{ pkgs, modulesPath, nur }:
let
  inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs)
    snakeOilPrivateKey snakeOilPublicKey;
  scripts = import ./scripts/scripts.nix { inherit pkgs; };
  melissa = import ./melissa.nix { inherit pkgs nur modulesPath; };
in {
  imports = [ nur.repos.kapack.modules.oar nur.repos.kapack.modules.ear melissa ];
  
  environment.systemPackages = [ pkgs.python3 pkgs.nano pkgs.mariadb pkgs.cpufrequtils pkgs.nur.repos.kapack.npb pkgs.openmpi pkgs.taktuk scripts.ear-mpirun];
  
  environment.variables.EAR_INSTALL_PATH = "${pkgs.nur.repos.kapack.ear}";
  environment.variables.EAR_ETC = "/etc";
  environment.variables.EAR_VERBOSE = "1";

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  networking.firewall.enable = false;

  users.users.user1 = { isNormalUser = true; home = "/users/user1"; };
  users.users.user2 = { isNormalUser = true; home = "/users/user2"; };

  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "*"; item = "stack"; type = "-"; value = "unlimited"; }
    { domain = "*"; item = "nofile"; type = "-"; value = "unlimited"; }
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

  environment.etc."oar/ear_newjob.sh".source = scripts.ear_newjob;
  environment.etc."oar/ear_endjob.sh".source = scripts.ear_endjob;

  services.oar = {
    # oar db passwords
    database = {
      host = "server";
      passwordFile = "/etc/oar-dbpassword";
      initPath = [ pkgs.util-linux pkgs.gawk pkgs.jq scripts.add_resources scripts.wait_db ];
      postInitCommands = scripts.oar_db_postInitCommands;
    };
    server.host = "server";
    privateKeyFile = "/etc/privkey.snakeoil";
    publicKeyFile = "/etc/pubkey.snakeoil";
    extraConfig = {
      HIERARCHY_LABELS="resource_id,core,network_address";
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
