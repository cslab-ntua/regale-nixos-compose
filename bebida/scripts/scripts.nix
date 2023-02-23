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
      for node in $(uniq $OAR_FILE_NODES)
      do
          oardodo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml drain --force --grace-period=5 --ignore-daemonsets --delete-local-data $node
      done
    '';
  bebida_epilog = pkgs.writeShellScript "bebida_epilog"
    ''
      for node in $(uniq $OAR_FILE_NODES)
      do
          oardodo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml uncordon $node
      done
    '';
}
