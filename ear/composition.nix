{ pkgs, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs; };
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
      
      node11 = { ... }: {
        imports = [ commonConfig ];
        services.ear.daemon.enable = true;
        services.ear.db_manager.enable = true;
      };
      
      node12 = { config, ... }: {
        imports = [ commonConfig ];
        services.ear.daemon.enable = true;
        services.ear.db_manager.enable = true;
      };
    };
  
  testScript = ''
      eardb.succeed("true")
  '';
}
