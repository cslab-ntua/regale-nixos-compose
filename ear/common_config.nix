{ pkgs, nur }:
{
  imports = [ nur.repos.kapack.modules.ear ];

  environment.systemPackages = [ pkgs.nano pkgs.mariadb pkgs.cpufrequtils pkgs.nur.repos.kapack.npb
                               pkgs.openmpi ];

  environment.variables.EAR_INSTALL_PATH = "${pkgs.nur.repos.kapack.ear}";
  environment.variables.EAR_VERBOSE = "1";

  # Allow root yo use open-mpi
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT = "1";
  environment.variables.OMPI_ALLOW_RUN_AS_ROOT_CONFIRM = "1";

  users.users.user1 = { isNormalUser = true; };
  users.users.user2 = { isNormalUser = true; };

  environment.etc."ear-dbpassword".text = ''
    DBUser=ear_daemon
    DBPassw=password
    # User and password for usermode querys.
    DBCommandsUser=ear_commands
    DBCommandsPassw=password
  '';

  services.ear = {
    database = {
      host = "eardb";
      passwordFile = "/etc/ear-dbpassword";
    };
    extraConfig = { Island = "0 DBIP=node11 DBSECIP=node12 Nodes=node1[1-2]";};
  };
}
