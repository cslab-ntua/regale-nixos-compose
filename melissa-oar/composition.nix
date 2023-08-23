{
  pkgs,
  modulesPath,
  nur,
  helpers,
  setup,
  flavour,
  ...
}: {
  dockerPorts.frontend = ["8443:443" "8000:80"];

  roles = let
    commonConfig = pkgs.regale.oar-config {inherit pkgs modulesPath nur flavour;};
    melissa = pkgs.regale.melissa-config {inherit pkgs modulesPath nur;};
  in {
    frontend = {...}: {
      imports = [commonConfig melissa];
      nxc.sharedDirs."/users".server = "server";

      services.oar.client.enable = true;
    };
    server = {...}: {
      imports = [commonConfig melissa];
      nxc.sharedDirs."/users".export = true;

      services.oar.server.enable = true;
      services.oar.dbserver.enable = true;
    };
    node = {...}: {
      imports = [commonConfig melissa];
      nxc.sharedDirs."/users".server = "server";

      services.oar.node.enable = true;
    };
  };

  rolesDistribution = {node = 2;};

  testScript = ''
    # Submit job with script under user1
  '';
}
