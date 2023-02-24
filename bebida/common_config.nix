{ pkgs, modulesPath, nur }:
let
  inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs)
    snakeOilPrivateKey snakeOilPublicKey;
  scripts = import ./scripts/scripts.nix { inherit pkgs; };
in
{
  imports = [
    nur.repos.kapack.modules.oar
  ];

  environment.systemPackages = [
    pkgs.python3
    pkgs.vim
    pkgs.cpufrequtils
    pkgs.python3Packages.clustershell
    pkgs.taktuk
    pkgs.htop
    pkgs.tree
  ];

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  nxc.users = { names = [ "user1" "user2" ]; prefixHome = "/users"; };

  systemd.enableUnifiedCgroupHierarchy = false;

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

  environment.etc."oar/bebida_prolog.sh".source = scripts.bebida_prolog;
  environment.etc."oar/bebida_epilog.sh".source = scripts.bebida_epilog;

  services.oar = {
    # oar db passwords
    database = {
      host = "server";
      passwordFile = "/etc/oar-dbpassword";
      initPath = [ pkgs.util-linux pkgs.gawk pkgs.jq scripts.add_resources ];
      postInitCommands = scripts.oar_db_postInitCommands;
    };
    server.host = "server";
    privateKeyFile = "/etc/privkey.snakeoil";
    publicKeyFile = "/etc/pubkey.snakeoil";
    #extraConfig = {
    #  PROLOGUE_EXEC_FILE = "/etc/oar/bebida_prolog.sh";
    #  EPILOGUE_EXEC_FILE = "/etc/oar/bebida_epilog.sh";
    #};
  };
}
