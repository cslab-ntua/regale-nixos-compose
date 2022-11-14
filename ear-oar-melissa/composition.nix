{ pkgs, modulesPath, nur, helpers, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
      melissaConfig = import ./melissa.nix { inherit pkgs modulesPath nur; };

      fileSystemsNFSShared = {
        device = "server:/";
        fsType = "nfs";
      };

      node = { ... }: {
        imports = [ commonConfig melissaConfig ];
        fileSystems."/users" = fileSystemsNFSShared;
        services.oar.node.enable = true;
        services.ear.daemon.enable = true;
        services.ear.db_manager.enable = true;
      };
    in {
      frontend = { ... }: {
        imports = [ commonConfig melissaConfig ];
        fileSystems."/users" = fileSystemsNFSShared;
        services.oar.client.enable = true;
      };
      server = { ... }: {
        imports = [ commonConfig ];
        services.oar.server.enable = true;
        services.oar.dbserver.enable = true;
        services.ear.database.enable = true;
        # NFS shared users' home
        services.nfs.server.enable = true;
        services.nfs.server.exports = ''
          /users *(rw,no_subtree_check,fsid=0,no_root_squash)
        '';
        nxc.postBootCommands = "mkdir -p /users && chmod 777 /users";
      };
      eargm = { ... }: {
        imports = [ commonConfig ];
        services.ear.global_manager.enable = true;
      };
    } // helpers.makeMany node "node" 2;

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
