{
  description = "OAR - basic setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    nxc.url = "git+https://gitlab.inria.fr/nixos-compose/nixos-compose.git?ref=nixpkgs-2305";
    nxc.inputs.nixpkgs.follows = "nixpkgs";
    NUR.url = "github:nix-community/NUR";
    kapack.url = "github:oar-team/nur-kapack?ref=regale";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nxc,
    NUR,
    kapack,
  }: let
    system = "x86_64-linux";
  in {
    packages.${system} = nxc.lib.compose {
      inherit nixpkgs system NUR;
      repoOverrides = {inherit kapack;};
      setup = ./setup.toml;
      compositions = ./compositions.nix;
    };

    devShell.${system} = nxc.devShells.${system}.nxcShell;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
