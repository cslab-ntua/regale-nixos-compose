{ pkgs, modulesPath, nur }:
let
  inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs)
    snakeOilPrivateKey snakeOilPublicKey;

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
in {
  imports = [ nur.repos.kapack.modules.oar  ];  
  environment.systemPackages = [ pkgs.python3 pkgs.nano pkgs.nur.repos.kapack.npb pkgs.openmpi ];

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";
  
  nxc.users = { names = ["user1" "user2"]; prefixHome = "/users"; };

  # Warning trigger issue w/ flavour Docker (su user1 denied)
  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "*"; item = "stack"; type = "-"; value = "unlimited"; }
  ];

  environment.etc."privkey.snakeoil" = {
    mode = "0600";
    source = snakeOilPrivateKey;
  };
  environment.etc."pubkey.snakeoil" = {
    mode = "0600";
    #source = snakeOilPublicKey;
    text = snakeOilPublicKey;
  };
  environment.etc."oar-dbpassword".text = ''
    # DataBase user name
    DB_BASE_LOGIN="oar"

    # DataBase user password
    DB_BASE_PASSWD="oar"

    # DataBase read only user name
    DB_BASE_LOGIN_RO="oar_ro"

    # DataBase read only user password
    DB_BASE_PASSWD_RO="oar_ro"
  '';
  services.oar = {
    # oar db passwords
    database = {
      host = "server";
      passwordFile = "/etc/oar-dbpassword";
      initPath = [ pkgs.util-linux pkgs.gawk pkgs.jq add_resources];
      postInitCommands = ''
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
    };
    server.host = "server";
    privateKeyFile = "/etc/privkey.snakeoil";
    publicKeyFile = "/etc/pubkey.snakeoil";
  };
}
