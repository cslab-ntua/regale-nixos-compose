{ pkgs, modulesPath, nur }:
let inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs) snakeOilPrivateKey snakeOilPublicKey;
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
in {
  imports = [ nur.repos.kapack.modules.oar ];

  environment.systemPackages = [
    pkgs.python3
    pkgs.nano
    pkgs.neovim
    pkgs.mariadb
    pkgs.cpufrequtils
    pkgs.nur.repos.kapack.npb
    pkgs.openmpi
    pkgs.taktuk
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "python3.9-poetry-1.1.12"
  ];

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  networking.firewall.enable = false;
  users.users.user1 = { isNormalUser = true; };
  users.users.user2 = { isNormalUser = true; };

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

  environment.variables.add_res = "${add_resources}";
  services.oar = {
    # oar db passwords
    database = {
      host = "server";
      passwordFile = "/etc/oar-dbpassword";
      initPath = [ pkgs.util-linux pkgs.gawk pkgs.jq wait_db add_resources];
      postInitCommands = ''
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
      ${nur.repos.kapack.oar3}/bin/.oarproperty -a core || true
      add_resources $num_nodes $num_cores
      '';
    };
    server.host = "server";
    privateKeyFile = "/etc/privkey.snakeoil";
    publicKeyFile = "/etc/pubkey.snakeoil";
    extraConfig = {
      HIERARCHY_LABELS="core,resource_id";
    };
  };

  users.users.root.password = "nixos";
  services.openssh.permitRootLogin = "yes";
}
