{ pkgs, modulesPath, helpers, flavour, nur, ... }: {

  roles = {
    nodes = { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.nur.repos.kapack.regale-library
        ];
      };
  };
  rolesDistribution = { nodes = 3; };

  testScript = ''
    foo.succeed("true")
  '';
}
