{ pkgs, lib, nur, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs lib nur; };
    in {
      node1 = { ... }: {
        imports = [ commonConfig ];
      };
      
      #node2 = { ... }: {
      #  imports = [ commonConfig ];
      #};
    };
  
  testScript = ''
  # TODO as exercice ;)      
  '';
}
