{ pkgs }:
{
  add_resources = pkgs.writers.writePython3Bin "add_resources"
    {
      libraries = [ pkgs.nur.repos.kapack.oar ];
    } ''
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

  bebida_prolog = pkgs.writeShellScript "bebida_prolog"
    ''
      export OAR_JOB_ID=$1
      export PATH=$PATH:/run/current-system/sw/bin:/run/wrappers/bin
      (
      echo Enter BEBIDA prolog
      printenv
      id
      for node in $(oarstat -J -j "$OAR_JOB_ID" -p | jq ".[\"$OAR_JOB_ID\"][] | .network_address" -r)
      do
        echo == Removing node $node
        oardodo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml drain --force --grace-period=5 --ignore-daemonsets --delete-emptydir-data --timeout=15s $node
        echo == Removed node $node
      done
      ) > /tmp/oar-''${OAR_JOB_ID}-prolog-logs 2> /tmp/oar-''${OAR_JOB_ID}-prolog-logs
    '';
  bebida_epilog = pkgs.writeShellScript "bebida_epilog"
    ''
      export OAR_JOB_ID=$1
      export PATH=$PATH:/run/current-system/sw/bin:/run/wrappers/bin
      (
      echo BEBIDA epilog
      printenv
      id
      for node in $(oarstat -J -j "$OAR_JOB_ID" -p | jq ".[\"$OAR_JOB_ID\"][] | .network_address" -r)
      do
        echo == Adding node $node
        oardodo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml uncordon $node
        echo == Added node $node
      done
      ) > /tmp/oar-''${OAR_JOB_ID}-epilog-logs 2> /tmp/oar-''${OAR_JOB_ID}-epilog-logs
    '';
}
