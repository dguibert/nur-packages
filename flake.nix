{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
  };

  outputs = { self, nixpkgs, nix }: let
    systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays =  [
          self.overlay
          nix.overlay
        ];
        config.allowUnfree = true;
    });

  in rec {

    packages = nixpkgsFor;

    devShell = forAllSystems (s: with nixpkgsFor.${s}; mkEnv {
      name = "nix";
      buildInputs = [ pkgs.nix jq ];
    });

    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules = {
      qemu-user = import ./modules/qemu-user.nix;
    };

    overlay = overlays.default;

    overlays = import ./overlays;
  };
}
