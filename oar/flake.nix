{
  description = "OAR - basic setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.05";
    nxc.url = "git+https://gitlab.inria.fr/nixos-compose/nixos-compose.git";
    nxc.inputs.nixpkgs.follows = "nixpkgs";
    NUR.url = "github:nix-community/NUR";
    kapack.url = "github:oar-team/nur-kapack/master";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nxc, NUR, kapack }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = nxc.lib.compose {
      inherit nixpkgs system NUR;
      repoOverrides = { inherit kapack; };
      composition = ./composition.nix;
    };

    devShell.${system} = nxc.devShells.${system}.nxcShell.overrideAttrs (base: {
      buildInputs = base.buildInputs ++ [ pkgs.tmux ];
    });
  };
}
