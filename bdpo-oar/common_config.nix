{ pkgs, modulesPath, nur }:
let
  inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs)
    snakeOilPrivateKey snakeOilPublicKey;
  scripts = import ./scripts/scripts.nix { inherit pkgs; };
in {
  imports = [
    nur.repos.kapack.modules.oar
    nur.repos.kapack.modules.bdpo
  ];
  
  environment.systemPackages = [
    pkgs.python3
    pkgs.vim
    pkgs.cpufrequtils
    pkgs.nur.repos.kapack.npb
    pkgs.nur.repos.kapack.bdpo
    pkgs.openmpi
    pkgs.python3Packages.clustershell
    pkgs.taktuk
  ];

  #
  # These below options are needed only for nodes and already setted 
  # in e
  #boot.kernelModules = [ "msr" "acpi_cpufreq" ];
  # Allow to cgroup v1 alongside cgroup v2
  #systemd.enableUnifiedCgroupHierarchy = false;


  
  #environment.variables.BDPO_INSTALL_PATH = "${pkgs.nur.repos.kapack.bdpo}";

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  users.users.user1 = { isNormalUser = true; home = "/users/user1"; };
  users.users.user2 = { isNormalUser = true; home = "/users/user2"; };

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

  environment.etc."oar/bdpo_prolog.sh".source = scripts.bdpo_prolog;
  environment.etc."oar/bdpo_epilog.sh".source = scripts.bdpo_epilog;
  environment.etc."oar/bdpo_oar.sh".source = scripts.bdpo_oar;
  
  services.oar = {
    # oar db passwords
    database = {
      host = "server";
      passwordFile = "/etc/oar-dbpassword";
      initPath = [ pkgs.util-linux pkgs.gawk pkgs.jq scripts.add_resources];
      postInitCommands = scripts.oar_db_postInitCommands;
    };
    server.host = "server";
    privateKeyFile = "/etc/privkey.snakeoil";
    publicKeyFile = "/etc/pubkey.snakeoil";
    extraConfig = {
      PROLOGUE_EXEC_FILE="/etc/oar/bdpo_prolog-debug.sh";
      EPILOGUE_EXEC_FILE="/etc/oar/bdpo_epilog-debug.sh";
    };
  };

  users.users.root.password = "nixos";
  services.openssh.permitRootLogin = "yes";
}
