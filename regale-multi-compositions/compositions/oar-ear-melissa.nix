{
  pkgs,
  modulesPath,
  nur,
  helpers,
  setup,
  flavour,
  ...
}: {
  nodes = let
    commonConfig = import ../lib/oar_config.nix {inherit pkgs modulesPath nur flavour;};
    earConfig = import ../lib/ear_config.nix {inherit pkgs modulesPath nur setup;};
    melissa = {
      pkgs,
      modulesPath,
      nur,
      ...
    }: {
      environment.variables.MELISSA_SRC = "${pkgs.nur.repos.kapack.melissa-launcher.src}";
      environment.systemPackages = [
        pkgs.nur.repos.kapack.melissa-heat-pde
        pkgs.nur.repos.kapack.melissa-launcher
      ];
      security.pam.loginLimits = [
        { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
        { domain = "*"; item = "stack"; type = "-"; value = "unlimited"; }
      ]; 
    };
  in {
    frontend = {...}: {
      imports = [commonConfig earConfig melissa];
      nxc.sharedDirs."/users".server = "server";

      services.oar.client.enable = true;
      services.oar.web.enable = true;
      services.oar.web.drawgantt.enable = true;
      services.oar.web.monika.enable = true;
    };
    server = {...}: {
      imports = [commonConfig earConfig melissa];
      nxc.sharedDirs."/users".export = true;

      services.oar.server.enable = true;
      services.oar.dbserver.enable = true;
      services.ear.database.enable = true;
    };
    eargm = {...}: {
      imports = [commonConfig earConfig melissa];
      nxc.sharedDirs."/users".server = "server";

      services.ear.global_manager.enable = true;
    };

    node = {...}: {
      imports = [commonConfig earConfig melissa];
      nxc.sharedDirs."/users".server = "server";
      systemd.enableUnifiedCgroupHierarchy = false;
      services.oar.node.enable = true;
      services.ear.daemon.enable = true;
      services.ear.db_manager.enable = true;
    };
  };

  rolesDistribution = {node =3;};

  testScript = ''
    # Submit job with script under user1
    frontend.succeed('su - user1 -c "cd && oarsub -l nodes=2 \"ear-mpirun cg.C.mpi\""')

    # Wait output job file
    frontend.wait_for_file('/users/user1/OAR.1.stdout')

    # Check job's final state
    frontend.succeed("oarstat -j 1 -s | grep Terminated")

    # Wait for monitoring data availability w/ timeout (10s) and save then in file
    node1.execute("""sec=0; until [ -f result ] || [ $sec -gt 9 ]; \
    do eacct -c result; \
    sleep 1; \
    sec=$((sec + 1)); \
    done
    """)

    # Test if monitoring data file exists
    node1.succeed('[ -f result ]')

  '';
}
