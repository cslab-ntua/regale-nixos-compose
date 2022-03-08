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

  # environment.etc."post-boot-script-01-add-island0-ear-conf" = {
  #   mode = "0755";
  #   source = pkgs.writeText "add-island0-ear-conf" ''
  #     #!${pkgs.bash}/bin/bash
  #     touch /etc/yopyop
  #     echo "Island=0 Nodes=node1[1-2]" >> /etc/ear/ear.conf 
  #   '';
  # };

  services.ear = {
    database = {
      host = "eardb";
      passwordFile = "/etc/ear-dbpassword";
    };
    extraConfig = { Island = "0 Nodes=node1[1-2]";};
  };
}
