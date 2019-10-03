
{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri = "github:dguibert/nixpkgs/pu";
  };

  outputs = { self, nixpkgs }: let
    pkgs = import ../../pkgs.nix {
      inherit nixpkgs;
      localSystem = { system = "x86_64-linux"; };# FIXME hard coded for now
      overlays = [ (import ../../overlays/local-genji.nix) ];
    };
    in rec {

    ## - packages: A set of derivations used as a default by most nix commands. For example, nix run nixpkgs:hello uses the packages.hello attribute of the nixpkgs flake. It cannot contain any non-derivation attributes. This also means it cannot be a nested set! (The rationale is that supporting nested sets requires Nix to evaluate each attribute in the set, just to discover which packages are provided.)
    #packages.hello = nixpkgs.provides.packages.hello;
    packages = {
      inherit (pkgs) hello nix;
    };

    ## - defaultPackage: A derivation used as a default by most nix commands if no attribute is specified. For example, nix run dwarffs uses the defaultPackage attribute of the dwarffs flake.
    defaultPackage = packages.hello;
    ##
    ## - checks: A non-nested set of derivations built by the nix flake check command, and by Hydra if a flake does not have a hydraJobs attribute.
    checks.hello = packages.hello;
    ##
    ## - hydraJobs: A nested set of derivations built by Hydra.
    ##
    ## - devShell: A derivation that defines the shell environment used by nix dev-shell if no specific attribute is given. If it does not exist, then nix dev-shell will use defaultPackage.
    devShell = with pkgs; mkEnv {
      name = "nix-genji";
      buildInputs = [ nixFlakes jq bashInteractive ];
      shellHook = ''
        unset NIX_STORE
	export XDG_CACHE_HOME=$HOME/.cache/nix-genji
	#export SHELL=${bashInteractive}/bin/bash
      '';
    };
    ## -
    ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
    lib = pkgs.lib;
    #builders
    #htmlDocs
    #legacyPackages
    overlays = pkgs.overlays;
  };
}
