{ pkgs, modulesPath, nur, helpers, setup, ... }: {
  roles =
    let
      commonConfig = import ./common_config.nix { inherit pkgs modulesPath nur setup; };
    in {
      frontend = { ... }: {
        imports = [ commonConfig ];
        nxc.sharedDirs."/users".server = "server";
        
        services.oar.client.enable = true;
        #services.oar.web.enable = true;
        #services.oar.web.drawgantt.enable = true;
        #services.oar.web.monika.enable = true;
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
      };
  
    };
  
  rolesDistribution = { node = 2; };
  
  testScript = ''
  # Submit job with script under user1

  '';
}
