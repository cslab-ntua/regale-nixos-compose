{ pkgs, modulesPath, mkIf, nur }: {

  imports = [ nur.repos.kapack.modules.oar nur.repos.kapack.modules.ear ];

  environment.systemPackages = [ pkgs.python3 pkgs.nano pkgs.mariadb pkgs.cpufrequtils pkgs.nur.repos.kapack.npb pkgs.openmpi pkgs.taktuk ];

  environment.variables.EAR_INSTALL_PATH = "${pkgs.nur.repos.kapack.ear}";
  environment.variables.EAR_ETC = "/etc";
  environment.variables.EAR_VERBOSE = "1";

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

}
