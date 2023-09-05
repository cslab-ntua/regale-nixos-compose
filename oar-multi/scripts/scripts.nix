{pkgs}:
with pkgs.writers; {
  prepare_cgroup =
    pkgs.writeShellScript "prepare_cgroup"
    ''
      # This script prepopulates OAR cgroup directory hierarchy, as used in the
      # job_resource_manager_cgroups.pl script, in order to have nodes use different
      # subdirectories and avoid conflitcs due to having all nodes actually running on
      # the same host machine

      OS_CGROUPS_PATH="/sys/fs/cgroup"
      CGROUP_SUBSYSTEMS="cpuset cpu cpuacct devices freezer blkio"
      if [ -e "$OS_CGROUPS_PATH/memory" ]; then
        CGROUP_SUBSYSTEMS="$CGROUP_SUBSYSTEMS memory"
      fi
      CGROUP_DIRECTORY_COLLECTION_LINKS="/dev/oar_cgroups_links"


      if [ "$1" = "init" ]; then
          mkdir -p $CGROUP_DIRECTORY_COLLECTION_LINKS && \
          for s in $CGROUP_SUBSYSTEMS; do
            mkdir -p $OS_CGROUPS_PATH/$s/oardocker/$HOSTNAME
            ln -s $OS_CGROUPS_PATH/$s/oardocker/$HOSTNAME $CGROUP_DIRECTORY_COLLECTION_LINKS/$s
          done
          ln -s $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME /dev/cpuset

          cat $OS_CGROUPS_PATH/cpuset/cpuset.cpus > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpus
          cat $OS_CGROUPS_PATH/cpuset/cpuset.mems > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.mems
          /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpu_exclusive
          /bin/echo 1000 > $OS_CGROUPS_PATH/cpuset/oardocker/notify_on_release

          cat $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpus > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.cpus
          cat $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.mems > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.mems
          /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.cpu_exclusive
          /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/notify_on_release
          /bin/echo 1000 > $OS_CGROUPS_PATH/blkio/oardocker/$HOSTNAME/blkio.weight
      elif [ "$1" = "clean" ]; then
          if [ "$HOSTNAME" = "node1" ]; then
              CGROOT="$OS_CGROUPS_PATH/cpuset/oardocker/"

              if ! [ -d $CGROOT ]; then
                echo "No such directory: $CGROOT"
                exit 0;
              fi

              echo "kill all cgroup tasks"
              while read task; do
                  echo "kill -9 $task"
                  kill -9 $task
              done < <(find $CGROOT -name tasks -exec cat {} \;)

              wait
              echo "Wipe all cgroup content"
              find $CGROOT -depth -type d -exec rmdir {} \;

              echo "Cgroup is cleanded!"
          fi
      fi

      exit 0
    '';

  wait_db =
    pkgs.writers.writePython3Bin "wait_db" {
      libraries = [pkgs.nur.repos.kapack.oar];
    } ''
      from oar.lib.tools import get_date
      from oar.lib.globals import init_and_get_session
      import time
      r = True
      n_try = 10000


      session = None
      while n_try > 0 and r:
          n_try = n_try - 1
          try:
              session = init_and_get_session()
              print(get_date(session))  # date took from db (test connection)
              r = False
          except Exception:
              print("DB is not ready")
              time.sleep(0.25)
    '';

  add_resources =
    pkgs.writers.writePython3Bin "add_resources" {
      libraries = [pkgs.nur.repos.kapack.oar];
    } ''
      from oar.lib.resource_handling import resources_creation
      from oar.lib.globals import init_and_get_session
      import sys

      session = init_and_get_session()

      resources_creation(session, "node", int(sys.argv[1]), int(sys.argv[2]))
    '';

  oar_db_postInitCommands = ''
    # Make sure it fails on error
    set -eux

    num_cores=$(( $(lscpu | awk '/^Socket\(s\)/{ print $2 }') * $(lscpu | awk '/^Core\(s\) per socket/{ print $4 }') ))
    echo $num_cores > /etc/num_cores


    if [[ -f /etc/nxc/deployment-hosts ]]; then
      num_nodes=$(grep node /etc/nxc/deployment-hosts | wc -l)
    else
      num_nodes=$(jq -r '[.nodes[] | select(contains("node"))]| length' /etc/nxc/deployment.json)
    fi
    echo $num_nodes > /etc/num_nodes

    wait_db
    ${pkgs.nur.repos.kapack.oar3}/bin/.oarproperty -a core || true
    add_resources $num_nodes $num_cores
  '';

  ear_newjob =
    pkgs.writeShellScript "ear_newjob"
    ''
      uniq $OAR_FILE_NODES > "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
      $EAR_INSTALL_PATH/bin/oar-ejob 50001 newjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID" &> /tmp/ear_newjob
      echo $?
    '';

  ear_endjob =
    pkgs.writeShellScript "ear_endjob"
    ''
      $EAR_INSTALL_PATH/bin/oar-ejob 50001 endjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID" &> /tmp/ear_endjob
      echo $?
      #rm "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
    '';

  ear-mpirun =
    writeBashBin "ear-mpirun"
    ''
      mpirun --hostfile $OAR_NODEFILE -mca pls_rsh_agent oarsh -mca btl tcp,self \
      -x LD_PRELOAD=$EAR_INSTALL_PATH/lib/libearld.so \
      -x OAR_EAR_LOAD_MPI_VERSION=ompi \
      -x OAR_EAR_LOADER_VERBOSE=4 \
      -x OAR_STEP_NUM_NODES=$(uniq $OAR_NODEFILE | wc -l) \
      -x OAR_JOB_ID=$OAR_JOB_ID \
      -x OAR_STEP_ID=0 \
      $@
    '';

  ear_suspendAction =
    writeBashBin "ear_suspendaction"
    ''
      export EAR_TMP=/var/lib/ear

      echo "###############################################################" >> $EAR_TMP/ear_power_save.log
      echo "EAR powercap suspend action: current_power $1 current_limit $2 total_idle_nodes $3 total_idle_power $4"   >> $EAR_TMP/ear_power_save.log
      echo "###############################################################"  >> $EAR_TMP/ear_power_save.log


      echo $(whoami) >> $EAR_TMP/ear_power_save.log
      echo "`date` Suspend invoked " >> $EAR_TMP/ear_power_save.log

      export HOSTLIST=$( ${pkgs.openssh}/bin/ssh server oarnodes | grep  "network_address: " | uniq | sort -hr | sed 's/network_address: //g' | head -n 1)

      for i in $HOSTLIST
      do
                      echo $i >> $EAR_TMP/ear_stopped_nodes.txt
                      echo "Node $i set to DRAIN " >> $EAR_TMP/ear_power_save.log
                      echo ${pkgs.openssh}/bin/ssh server oarnodesetting -h $i -s Absent -p available_upto=0 >> $EAR_TMP/ear_power_save.log
                      ${pkgs.openssh}/bin/ssh server oarnodesetting -h $i -s Absent -p available_upto=0
      done
    '';

  ear_resumeAction =
    writeBashBin "ear_resumeaction"
    ''
      set -x

      export EAR_TMP=/var/lib/ear

      echo "###############################################################" >> $EAR_TMP/ear_power_save.log
      echo "EAR powercap resume action: current_power $1 current_limit $2 total_idle_nodes $3 total_idle_power $4" >> $EAR_TMP/ear_power_save.log
      echo "###############################################################" >> $EAR_TMP/ear_power_save.log
      echo "`date` Resume invoked " >> $EAR_TMP/ear_power_save.log

      export HOSTLIST="$(echo $(cat $EAR_TMP/ear_stopped_nodes.txt))"


      for i in $HOSTLIST
      do
          echo "Setting idle node=$i" >> $EAR_TMP/ear_power_save.log
          ${pkgs.openssh}/bin/ssh server oarnodesetting -h $i -s Alive -p available_upto=2147483647 >> $EAR_TMP/ear_power_save.log
      done

      rm -f $EAR_TMP/ear_stopped_nodes.txt
    '';
}
