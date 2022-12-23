{ pkgs, lib, nur, ... }: {
  roles =
    let
      commonConfig = import ./common_config.nix { inherit pkgs lib nur; };
    in {
      node = { ... }: {
        imports = [ commonConfig ];
      };
    };

  rolesDistribution = { node = 2; };
  
  testScript = ''
  # TODO as exercice ;)      
  '';
}
