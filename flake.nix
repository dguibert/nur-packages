{
  description = "A flake for building my NUR packages";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nix, flake-utils }: let
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

    devShell = pkgs.mkEnv {
      name = "nix";
      buildInputs = with pkgs; [ pkgs.nix jq ];
    };

    checks = {
      "intel_2020_2_254" = legacyPackages.intelPackages_2020_2_254.compilers;
    };
  })) // rec {

    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules = import ./modules;

    overlay = overlays.default;

    overlays = import ./overlays;

  };
}
