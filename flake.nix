{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
  };

  outputs = { self, nixpkgs, nix }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      #localSystem = { system = "x86_64-linux"; };# FIXME hard coded for now
      overlays =  [
        self.overlay
        nix.overlay
      ];
      config.allowUnfree = true;
    };

  in rec {

      packages.x86_64-linux = {
        inherit (pkgs) hello nix
        openmpi
        ;
      };

      devShell.x86_64-linux = with pkgs; mkEnv {
        name = "nix";
        buildInputs = [ pkgs.nix jq ];
      };

      ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
      nixosModules = {
        qemu-user = import ./modules/qemu-user.nix;
      };

      overlay = overlays.default;

      overlays = import ./overlays;
    };
}
