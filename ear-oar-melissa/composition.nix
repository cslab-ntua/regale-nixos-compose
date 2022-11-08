{ pkgs, modulesPath, nur, helpers, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
      node = { ... }: {
        imports = [ commonConfig ];

        environment.systemPackages = [
          pkgs.nur.repos.kapack.melissa-heat-pde
          pkgs.nur.repos.kapack.melissa-launcher
        ];

        services.oar.node = {
          enable = true;
        };

        # services.ear.daemon.enable = false;
        # services.ear.db_manager.enable = false;
      };

    in {
      frontend = { ... }: {
        imports = [ commonConfig ];


        environment.systemPackages = [
          pkgs.nur.repos.kapack.melissa-heat-pde
          pkgs.nur.repos.kapack.melissa-launcher
        ];

        services.oar.client.enable = true;
      };
      server = { ... }: {
        imports = [ commonConfig ];
        services.oar.server.enable = true;
        services.oar.dbserver.enable = true;
        # services.ear.database.enable = false;
      };
      eargm = { ... }: {
        imports = [ commonConfig ];
        # services.ear.global_manager.enable = false;
      };
    } // helpers.makeMany node "node" 2;


  testScript = ''
    frontend.succeed("true")
  '';
}
