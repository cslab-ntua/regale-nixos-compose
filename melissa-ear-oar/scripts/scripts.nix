{ pkgs }:
with pkgs.writers;
{
  wait_db = pkgs.writers.writePython3Bin "wait_db" {
    libraries = [ pkgs.nur.repos.kapack.oar ]; } ''
    from oar.lib.tools import get_date
    import time
    r = True
    while r:
        try:
            print(get_date())  # date took from db (test connection)
            r = False
        except Exception:
            print("DB is not ready")
            time.sleep(0.25)
  '';

  add_resources = pkgs.writers.writePython3Bin "add_resources" {
    libraries = [ pkgs.nur.repos.kapack.oar ]; } ''
    from oar.lib import db, Resource
    import sys


    def create_res(node_name, nb_nodes, nb_core=1, vfactor=1):
        for i in range(nb_nodes * nb_core * vfactor):
            Resource.create(
                network_address=f"{node_name}{int(i/(nb_core * vfactor)+1)}",
                cpuset=i % nb_core,
                core=i + 1,
                state="Alive",
            )
        db.commit()


    db.reflect()
    create_res("node", int(sys.argv[1]), int(sys.argv[2]))
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

  ear_newjob = pkgs.writeShellScript "ear_newjob"
  ''
    uniq $OAR_FILE_NODES > "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
    $EAR_INSTALL_PATH/bin/oar-ejob 50001 newjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID" &> /tmp/ear_newjob
    echo $?
  '';

  ear_endjob = pkgs.writeShellScript "ear_endjob"
  ''
    $EAR_INSTALL_PATH/bin/oar-ejob 50001 endjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID" &> /tmp/ear_endjob
    echo $?
    #rm "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
  '';

  ear-mpirun = writeBashBin "ear-mpirun"
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

  ear_suspendAction = writeBashBin "ear_suspendaction"
  ''
export EAR_TMP=/var/lib/ear

echo "###############################################################" >> $EAR_TMP/ear_power_save.log
echo "EAR powercap suspend action: current_power $1 current_limit $2 total_idle_nodes $3 total_idle_power $4"   >> $EAR_TMP/ear_power_save.log
echo "###############################################################"  >> $EAR_TMP/ear_power_save.log


echo $(whoami) >> $EAR_TMP/ear_power_save.log
echo "`date` Suspend invoked " >> $EAR_TMP/ear_power_save.log

export HOSTLIST=$( ${pkgs.openssh}/bin/ssh server oarnodes | grep  "network_address: " | uniq | sort -hr | sed 's/network_address: //g' | head -n 1)

for i in $${HOSTLIST}
do
                echo $${i} >> $EAR_TMP/ear_stopped_nodes.txt
                echo "Node $${i} set to DRAIN " >> $EAR_TMP/ear_power_save.log
                echo ${pkgs.openssh}/bin/ssh server oarnodesetting -h $${i} -s Absent -p available_upto=0 >> $EAR_TMP/ear_power_save.log
                ${pkgs.openssh}/bin/ssh server oarnodesetting -h $${i} -s Absent -p available_upto=0
done
  '';

  ear_resumeAction = writeBashBin "ear_resumeaction"
  ''
set -x

export EAR_TMP=/var/lib/ear

echo "###############################################################" >> $EAR_TMP/ear_power_save.log
echo "EAR powercap resume action: current_power $1 current_limit $2 total_idle_nodes $3 total_idle_power $4" >> $EAR_TMP/ear_power_save.log
echo "###############################################################" >> $EAR_TMP/ear_power_save.log
echo "`date` Resume invoked " >> $EAR_TMP/ear_power_save.log

export HOSTLIST="$(echo $(cat $EAR_TMP/ear_stopped_nodes.txt))"


for i in $${HOSTLIST}
do
    echo "Setting idle node=$${i}" >> $EAR_TMP/ear_power_save.log
    ${pkgs.openssh}/bin/ssh server oarnodesetting -h $${i} -s Alive -p available_upto=2147483647 >> $EAR_TMP/ear_power_save.log
done

rm -f $EAR_TMP/ear_stopped_nodes.txt
  '';

}
