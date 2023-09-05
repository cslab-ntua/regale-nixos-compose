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
    commonConfig = import ../lib/oar_config.nix {inherit pkgs modulesPath nur flavour;};
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
    };
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
