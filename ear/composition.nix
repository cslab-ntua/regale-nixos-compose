{ pkgs, nur, ... }: {
  roles =
    let
      commonConfig = import ./common_config.nix { inherit pkgs nur; };
    in {
      
      eardb = { ... }: {
        imports = [ commonConfig ];
        environment.systemPackages = [  ];
        services.ear.database.enable = true;
      };
      
      eargm = { ... }: {
        imports = [ commonConfig ];
        services.ear.global_manager.enable = true;
      };
      
      node = { ... }: {
        imports = [ commonConfig ];
        services.ear.daemon.enable = true;
        services.ear.db_manager.enable = true;
      };
    };
  
  rolesDistribution = { node = 2; };
  
  testScript = ''
  #prepare machine files for mpirun and eat
  node1.execute('yes node1  | head -n 16 > machines && yes node2  | head -n 16 >> machines')
  node1.execute('uniq machines > uniq_machines')

  #signal ear daemon for new job to monitor
  node1.execute('OAR_JOB_ID=1 OAR_USER=user1 oar-ejob 50001 newjob uniq_machines')

  #launch cgi.C.mpi application
  node1.succeed("""
  mpirun --hostfile machines --mca btl tcp,self \
  -x LD_PRELOAD=$EAR_INSTALL_PATH/lib/libearld.so \
  -x OAR_EAR_LOAD_MPI_VERSION=ompi \
  -x OAR_STEP_NUM_NODES=2 \
  -x OAR_JOB_ID=1 \
  -x OAR_STEP_ID=0 \
  cg.C.mpi
  """)

  #signal end of job
  node1.execute('OAR_JOB_ID=1 OAR_USER=user1 oar-ejob 50001 endjob uniq_machines')

  #wait for monitoring data availability w/ timeout (10s) and save then in file
  node1.execute("""sec=0; until [ -f result ] || [ $sec -gt 9 ]; \
  do eacct -c result; \ 
  sleep 1; \ 
  sec=$((sec + 1)); \
  done
  """)
  
  #test if monitoring data file exists 
  node1.succeed('[ -f result ]')
  '';
}
