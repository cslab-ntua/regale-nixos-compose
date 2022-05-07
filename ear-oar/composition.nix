{ pkgs, modulesPath, nur, helpers, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
      node = { ... }: {
        imports = [ commonConfig ];
        services.oar.node = {
          enable = true;
          #register = { enable = true; };
        };
        services.ear.daemon.enable = true;
        services.ear.db_manager.enable = true;
      };
      
    in {
      frontend = { ... }: {
        imports = [ commonConfig ];
        services.oar.client.enable = true;
      };
      server = { ... }: {
        imports = [ commonConfig ];
        services.oar.server.enable = true;
        services.oar.dbserver.enable = true;
        services.ear.database.enable = true;
      };
      eargm = { ... }: {
        imports = [ commonConfig ];
        services.ear.global_manager.enable = true;
      };
    } // helpers.makeMany node "node" 2;


  testScript = ''
    frontend.succeed("true")
  '';
}
