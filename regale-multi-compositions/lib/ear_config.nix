{ pkgs, modulesPath, nur, setup }:
let
  inherit (import "${toString modulesPath}/tests/ssh-keys.nix" pkgs)
    snakeOilPrivateKey snakeOilPublicKey;
  scripts = import ./scripts/scripts.nix { inherit pkgs; };
in {
  imports = [ nur.repos.kapack.modules.ear  ];

  systemd.enableUnifiedCgroupHierarchy = false;

  environment.systemPackages = [
    pkgs.python3
    pkgs.nano
    pkgs.mariadb
    pkgs.cpufrequtils
    pkgs.nur.repos.kapack.npb
    pkgs.nur.repos.kapack.ear

    pkgs.openmpi pkgs.taktuk

    scripts.ear-mpirun
    scripts.ear_suspendAction
    scripts.ear_resumeAction

    # scripts.oar_db_postInitCommands
    scripts.wait_db
    scripts.add_resources
  ];

  environment.variables.EAR_INSTALL_PATH = "${pkgs.nur.repos.kapack.ear}";
  environment.variables.EAR_ETC = "/etc";
  environment.variables.EAR_VERBOSE = "1";

  environment.etc."oar/ear_newjob.sh".source = scripts.ear_newjob;
  environment.etc."oar/ear_endjob.sh".source = scripts.ear_endjob;

  # Ear base configuration
  environment.etc."ear-dbpassword".text = ''
    DBUser=ear_daemon
    DBPassw=password
    # User and password for usermode querys.
    DBCommandsUser=ear_commands
    DBCommandsPassw=password
  '';

  services.ear = {
    ear_commands.enable = true;
    database = {
      host = "server";
      passwordFile = "/etc/ear-dbpassword";
    };
    extraConfig = {
      Island = "0 DBIP=node1 DBSECIP=node2 Nodes=node[1-${builtins.toString setup.params.nb_nodes}]";
      EARGMPowerLimit= setup.params.nb_nodes * 180;

      EARGMPowercapSuspendAction = "${scripts.ear_suspendAction}/bin/ear_suspendaction";
      EARGMPowercapSuspendLimit=90;
      EARGMPowercapResumeAction = "${scripts.ear_resumeAction}/bin/ear_resumeaction";
      EARGMPowercapResumeLimit=70;
    };
  };
}
