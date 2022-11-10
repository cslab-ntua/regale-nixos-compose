{ pkgs, modulesPath, nur, helpers, flavour, ... }: {
  extraVolumes = [ "/home/adfaure/Sandbox/nxc-melissa/srv:/fakefs:rw" ];
  nodes =
    let
      nfsConfigs = import ./nfs.nix { inherit flavour; };
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur; };
      node = { ... }: {
        imports = [ commonConfig  nfsConfigs.client ];

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
        imports = [ commonConfig  nfsConfigs.client ];

        environment.variables.MELISSA_SRC = "${pkgs.nur.repos.kapack.melissa-launcher.src}";

        environment.systemPackages = [
          pkgs.nur.repos.kapack.melissa-heat-pde
          pkgs.nur.repos.kapack.melissa-launcher
        ];

        services.oar.client.enable = true;
      };
      server = { ... }: {
        imports = [ commonConfig nfsConfigs.server ];
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
