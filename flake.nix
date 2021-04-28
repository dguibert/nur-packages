{
  description = "A flake for building my NUR packages";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  inputs.flake-utils.url      = "github:numtide/flake-utils";
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  outputs = { self, nixpkgs, nix, flake-utils, sops-nix }: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          self.overlay
          self.overlays.aocc
          self.overlays.flang
          self.overlays.intel-compilers
          self.overlays.arm
          self.overlays.pgi
          self.overlays.extra-builtins
          nix.overlay
        ];
        config.allowUnfree = true;
        config.psxe.licenseFile = "none"; #<secrets/lic>;
    };

  in (flake-utils.lib.eachDefaultSystem (system:
       let pkgs = nixpkgsFor system; in
       rec {

    legacyPackages = nixpkgsFor system;

    devShell = pkgs.callPackage ./shell.nix {
      inherit (sops-nix.packages.${system}) sops-pgp-hook ssh-to-pgp;
    };

    checks = {
      "intel_2020_2_254" = legacyPackages.intelPackages_2020_2_254.compilers;
    };
  })) // rec {

    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules = import ./modules;

    overlay = overlays.default;

    overlays = import ./overlays;

    templates = {
      env_flake = {
        path = ./templates/env_flake;
        description = "A bery basic env for my project";
      };
    };
    defaultTemplate = self.templates.env_flake;

  };
}
