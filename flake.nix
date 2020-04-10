{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
  };

  outputs = { self, nixpkgs, nix }@flakes: let
    systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays =  [
          nix.overlay
          self.overlay
        ];
        config.allowUnfree = true;
      }
    );


  in rec {
    lib = import ./lib { lib = nixpkgs.lib; };

      packages = nixpkgsFor;

      devShell.x86_64-linux = with nixpkgsFor.x86_64-linux; mkEnv {
        name = "nix";
        buildInputs = [
          nixpkgsFor.x86_64-linux.nix
          jq ];
        shellHook = ''
          unset NIX_INDENT_MAKE
          unset IN_NIX_SHELL NIX_REMOTE
          unset TMP TMPDIR

          export SHELL=${bashInteractive}/bin/bash

          NIX_PATH=
          ${lib.concatMapStrings (f: ''
            NIX_PATH+=:${toString f}=${toString flakes.${f}}
          '') (builtins.attrNames flakes) }
          export NIX_PATH

          NIX_OPTIONS=()
          NIX_OPTIONS+=("--option plugin-files ${(nixpkgsFor.x86_64-linux.nix-plugins.override { nix = nixpkgsFor.x86_64-linux.nix; }).overrideAttrs (o: {
              buildInputs = o.buildInputs ++ [ boehmgc ];
            })}/lib/nix/plugins/libnix-extra-builtins.so")
          NIX_OPTIONS+=("--option extra-builtins-file ${./lib/extra-builtins.nix}")
          export NIX_OPTIONS
        '';
      };

      ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
      nixosModules = {
      };

      overlay = overlays.default;

      overlays = import ./overlays;
    };
}
