{
  description = "nixos-compose - basic setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    NUR.url = "github:nix-community/NUR";
    kapack.url = "github:oar-team/nur-kapack?ref=regale";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, NUR, kapack }:
    let
      system = "x86_64-linux";
    in {
      overlay = final: prev: {
        regale.oar-config = import ./lib/oar_config.nix;
        regale.ear-config = import ./lib/ear_config.nix;
        regale.melissa-config = import ./lib/melissa_config.nix;
      };
    };
}
