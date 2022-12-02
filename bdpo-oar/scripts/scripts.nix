{ pkgs }:
with pkgs.writers;
{
  add_resources = pkgs.writers.writePython3Bin "add_resources" {
    libraries = [ pkgs.nur.repos.kapack.oar ]; } ''
    from oar.lib.tools import get_date
    from oar.lib.resource_handling import resources_creation
    import sys
    import time
    r = True
    while r:
        try:
            print(get_date())  # date took from db (test connection)
            r = False
        except Exception:
            print("DB is not ready")
            time.sleep(0.25)
    resources_creation("node", int(sys.argv[1]), int(sys.argv[2]))
  '';

  oar_db_postInitCommands = ''
      num_cores=$(( $(lscpu | awk '/^Socket\(s\)/{ print $2 }') * $(lscpu | awk '/^Core\(s\) per socket/{ print $4 }') ))
      echo $num_cores > /etc/num_cores
      
      if [[ -f /etc/nxc/deployment-hosts ]]; then
        num_nodes=$(grep node /etc/nxc/deployment-hosts | wc -l)
      else
        num_nodes=$(jq -r '[.nodes[] | select(contains("node"))]| length' /etc/nxc/deployment.json)
      fi
      echo $num_nodes > /etc/num_nodes
      
      add_resources $num_nodes $num_cores 
      '';

  bdpo_prolog = pkgs.writeShellScript "bdpo_prolog"
  '' 
    # OAR_JOB_TYPES defined for testing purposes only
    # OAR_JOB_TYPES="bdpo=monitor_and_optimize,bdpo_params.txt;..."
    uniq $OAR_FILE_NODES > "/tmp/uniq_oar_nodes_$OAR_JOB_ID"

    if [[ ";$OAR_JOB_TYPES;" =~ \;bdpo=(.*)\; ]]; then 
      IFS=',' read -ra BDPO_ARRAY <<< "''${BASH_REMATCH[1]}"
      BDPO_OAR_MODE=''${BDPO_ARRAY[0]}
      BDPO_PARAMS_FILE=''${BDPO_ARRAY[1]}
    fi

    # Building the command line to execute remotely on all the nodes.
    CLI=". /etc/oar/bdpo_oar.sh prolog $OAR_WORKDIR/$BDPO_PARAMS_FILE"
    # Starting BDPO on the specified nodes.
    if [[ "$BDPO_OAR_MODE" == "monitor_and_optimize" ]]; then
	    ${pkgs.python3Packages.clustershell}/bin/clush --hostfile="/tmp/uniq_oar_nodes_$OAR_JOB_ID" -O "ssh_options=-p 6667" "$CLI" &
    
    fi
  '';
  
  bdpo_epilog = pkgs.writeShellScript "bdpo_epilog"
  ''
    # Specific to OAR as describe in the file scripts/oar_epilog in OAR3 repo
    NODES=$(cat $OAR_NODEFILE | tr '\n' ' ')

    # Retrieve bpdo's mode and paramters file
    if [[ ";$OAR_JOB_TYPES;" =~ \;bdpo=(.*)\; ]]; then 
      IFS=',' read -ra BDPO_ARRAY <<< "''${BASH_REMATCH[1]}"
      BDPO_OAR_MODE=''${BDPO_ARRAY[0]}
      BDPO_PARAMS_FILE=''${BDPO_ARRAY[1]}
    fi

    # Building the command line to execute remotely on all the nodes.
    CLI=". /etc/oar/bdpo_oar.sh epilog $OAR_USER $OAR_JOB_ID $OAR_WORKDIR $OAR_WORKDIR/$BDPO_PARAMS_FILE"

    # Terminating BDPO on the specified nodes.
    if [[ "$BDPO_OAR_MODE" == "monitor_and_optimize" ]]; then
	    ${pkgs.python3Packages.clustershell}/bin/clush --hostfile="/tmp/uniq_oar_nodes_$OAR_JOB_ID" -O "ssh_options=-p 6667" "$CLI" &
    fi
  '';
  
  bdpo_oar= pkgs.writeShellScript "bdpo_oar"
  ''
    COMMAND=$1
    BDPO_PARAMS_FILE=$2
    OAR_USER=$2
    OAR_JOBID=$3
    OAR_WORKDIR=$4
    BDPO_PARAMS_FILE=$5
    PROLOGUE_BDPO_PARAMS_FILE=$2

    if [[ "$COMMAND" == "prolog" ]]; then
        BDPO_PARAMS_FILE=$PROLOGUE_BDPO_PARAMS_FILE       
    fi

    # Read the file line by line.
    while read -r line; do
      # Split the line into name and value using regex matching.
      if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
        name="''${BASH_REMATCH[1]}"
        value="''${BASH_REMATCH[2]}"
        if [[ "''${name:0:5}" == BDPO_ ]]; then
          printf -v "$name" %s "$value"
          export "$name"
        fi    
      fi
    done < <(oardodo cat $BDPO_PARAMS_FILE)

    if [[ "$COMMAND" == "prolog" ]]; then
      nohup 2> /dev/null oardodo stdbuf -o0 ${pkgs.nur.repos.kapack.bdpo}/bin/bdpo &
    elif [[ "$COMMAND" == "epilog" ]]; then
      # Terminate bdpo process
      oardodo kill $(cat /var/run/bdpo.pid)

      # Create bdpo dir for aggrated results
      BDPO_RESDIR="$OAR_WORKDIR/bdpo_results_$OAR_JOBID"
      oardodo mkdir -p "$BDPO_RESDIR"  
      oardodo chown "$OAR_USER" "$BDPO_RESDIR"
      oardodo chgrp users "$BDPO_RESDIR"

      # Aggregate results and transfer files' ownership
      oardodo ${pkgs.nur.repos.kapack.bdpo}/bin/bdpo_aggregate -o "$BDPO_RESDIR"
      for file in "$(oardodo find "$BDPO_RESDIR" -type f -name "$(hostname)-*")
      do
        oardodo chown "$OAR_USER" "$file"          
        oardodo chgrp users "$file"
      done
    else
      echo "Unknown command: $COMMAND"
      exit 1
    fi
  '';  
}
