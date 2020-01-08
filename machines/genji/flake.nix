
{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    #nixpkgs.uri = "github:dguibert/nixpkgs/pu";
    nixpkgs.uri = "/home/dguibert/code/nixpkgs";
    nix.uri = "/home/dguibert/code/nix";
  };


  outputs = { self, nixpkgs, nix }: let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
      overlays =  [
	overlays.default
        nix.overlay
        self.overlay
      ];
          config.allowUnfree = true;
        }
      );


    overlays = import ../../overlays;

  in rec {
    overlay = final: prev: {
      nixStore = "/home_nfs_home_nfs/bguibertd/nix";
    };

    devShell.x86_64-linux = with nixpkgsFor.x86_64-linux; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ nixpkgsFor.x86_64-linux.nix jq ];
      shellHook = ''
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        unset NIX_STORE
      '';
    };

  };
}
