{ pkgs, modulesPath, nur, helpers, ... }: {
  roles =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
    in {
      frontend = { ... }: {
        imports = [ commonConfig ];
        nxc.sharedDirs."/users".server = "server";

        services.oar.client.enable = true;
	      services.oar.web.enable = true;
    	  services.oar.web.drawgantt.enable = true;
    	  services.oar.web.monika.enable = true;
      };
      server = { ... }: {
        imports = [ commonConfig ];
        nxc.sharedDirs."/users".export = true;
        
        services.oar.server.enable = true;
        services.oar.dbserver.enable = true;
      };

      node = { ... }: {
        imports = [ commonConfig ];
        nxc.sharedDirs."/users".server = "server";
        
        services.oar.node.enable = true;
        # initial bdpo config setting
        services.bdpo.enable = true;
      };
    };

  testScript = ''
  # Submit job with script under user1
  frontend.succeed('su - user1 -c "cd && oarsub -l nodes=2 \"mpirun cg.C.mpi\""')
  
  # Wait output job file 
  frontend.wait_for_file('/users/user1/OAR.1.stdout')
  
  # Check job's final state
  frontend.succeed("oarstat -j 1 -s | grep Terminated")
  '';
}
