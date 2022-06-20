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
  imports = [ nur.repos.kapack.modules.oar nur.repos.kapack.modules.ear ];
  
  environment.systemPackages = [ pkgs.python3 pkgs.nano pkgs.mariadb pkgs.cpufrequtils pkgs.nur.repos.kapack.npb pkgs.openmpi pkgs.taktuk ];
  
  environment.variables.EAR_INSTALL_PATH = "${pkgs.nur.repos.kapack.ear}";
  environment.variables.EAR_ETC = "/etc";
  environment.variables.EAR_VERBOSE = "1";

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";
 
  networking.firewall.enable = false;
  users.users.user1 = { isNormalUser = true; };
  users.users.user2 = { isNormalUser = true; };

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
  environment.etc."oar/ear_newjob.sh".source = pkgs.writeShellScript "ear_newjob"
  ''
    uniq $OAR_FILE_NODES > "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
    $EAR_INSTALL_PATH/bin/oar-ejob 50001 newjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
  '';
  environment.etc."oar/ear_endjob.sh".source = pkgs.writeShellScript "ear_endjob"
  ''
    $EAR_INSTALL_PATH/bin/oar-ejob 50001 endjob "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
    #rm "/tmp/uniq_oar_nodes_$OAR_JOB_ID"
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
    extraConfig = {
      PROLOGUE_EXEC_FILE="/etc/oar/ear_newjob.sh";
      EPILOGUE_EXEC_FILE="/etc/oar/ear_endjob.sh";
    };
  };

  # Ear base configuration
  environment.etc."ear-dbpassword".text = ''
    DBUser=ear_daemon
    DBPassw=password
    # User and password for usermode querys.
    DBCommandsUser=ear_commands
    DBCommandsPassw=password
  '';

  services.ear = {
    database = {
      host = "server";
      passwordFile = "/etc/ear-dbpassword";
    };
    extraConfig = { Island = "0 DBIP=node1 DBSECIP=node2 Nodes=node[1-2]";};
  };

  users.users.root.password = "nixos";
  services.openssh.permitRootLogin = "yes";
}
