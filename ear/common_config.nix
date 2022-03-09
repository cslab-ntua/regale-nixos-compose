{ pkgs }:
{
  environment.systemPackages = [ pkgs.nano pkgs.mariadb pkgs.cpufrequtils ];

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
