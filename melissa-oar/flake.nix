{
  description = "OAR and melissa composition";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    nxc.url = "git+https://gitlab.inria.fr/nixos-compose/nixos-compose.git?ref=2305";
    nxc.inputs.nixpkgs.follows = "nixpkgs";
    NUR.url = "github:nix-community/NUR";
    kapack.url = "github:oar-team/nur-kapack?ref=nixpkgs-2305";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
    regale.url = "../regale-library";
  };

  outputs = { self, nixpkgs, nxc, NUR, kapack, regale }:
    let
      system = "x86_64-linux";
    in {
      packages.${system} = nxc.lib.compose {
        inherit nixpkgs system NUR;
        repoOverrides = { inherit kapack; };
        setup = ./setup.toml;
        composition = ./composition.nix;
        overlays = [ regale.overlay ];
      };

      devShell.${system} = nxc.devShells.${system}.nxcShell;
     };
}
