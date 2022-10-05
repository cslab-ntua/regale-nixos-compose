{ pkgs, nur, ... }: {
  nodes =
    let
      commonConfig = import ./common_config.nix { inherit pkgs nur; };
    in {
      
      examon_broker = { ... }: {
        imports = [ commonConfig ];
        environment.systemPackages = [  ];
        services.examon.broker.enable = true;
      };
            
      node1 = { ... }: {
        imports = [ commonConfig ];
      };
      
      node2 = { ... }: {
        imports = [ commonConfig ];
      };
    };
  
  testScript = ''
      node1.succeed("true")
  '';
}
