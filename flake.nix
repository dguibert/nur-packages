{
  description = "A flake for building my NUR packages";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-utils.url      = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nix, flake-utils }@inputs: let
    inherit (self) outputs;

    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          self.overlays.default
          self.overlays.extra-builtins
          nix.overlays.default
        ];
        config.allowUnfree = true;
    };

  in (flake-utils.lib.eachDefaultSystem (system:
       let pkgs = nixpkgsFor system; in
       rec {

    legacyPackages = nixpkgsFor system;

    devShell = pkgs.mkShell {
      name = "nix";
      ENVRC = "nix";
      buildInputs = with pkgs; [ pkgs.nix jq ];
    };

    checks = {
      "intel_2020_2_254" = legacyPackages.intelPackages_2020_2_254.compilers;
    };
  })) // rec {

    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    nixosModules = import ./modules;

    overlays = import ./overlays;

    templates = {
      env_flake = {
        path = ./templates/env_flake;
        description = "A bery basic env for my project";
      };
      terraform = {
        path = ./templates/terraform;
        description = "A template to use terranix/terraform";
      };
    };
    defaultTemplate = self.templates.env_flake;

  };
}
