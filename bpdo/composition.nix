{ pkgs, nur, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs nur; };
    in {
      node1 = { ... }: {
        imports = [ commonConfig ];
      };
      
      #node2 = { ... }: {
      #  imports = [ commonConfig ];
      #};
    };
  
  testScript = ''
      
  '';
}
