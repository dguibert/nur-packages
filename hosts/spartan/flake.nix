{
  description = "A flake for building my NUR packages on SPARTAN";

  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs = {
    nixpkgs.url          = "github:dguibert/nixpkgs/pu";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    nur_dguibert.url     = "github:dguibert/nur-packages/pu";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    #nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
    #nur_dguibert_envs.url= "/home/dguibert/nur-packages?dir=envs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs
            , nur_dguibert
            , nix
            , flake-utils
            }@flakes: let

      # Memoize nixpkgs for different platforms for efficiency.
      defaultPkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays =  [
            overlays.default
            nix.overlay
            (final: prev: {
              nixStore = (self.overlay final prev).nixStore;
            })
          ];
          config.allowUnfree = true;
        };
      nixpkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays =  [
            nix.overlay
            overlays.default
            self.overlay
          ];
          config.allowUnfree = true;
        };

    overlays = import ../../overlays;

  in (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
       let pkgs = nixpkgsFor system;
           defPkgs = defaultPkgsFor system;
       in rec {

    legacyPackages = pkgs;

    defaultApp = apps.nix;
    apps.nix = flake-utils.lib.mkApp { drv = pkgs.writeScriptBin "nix-spartan" (with defPkgs; let
        name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      in ''
        #!${runtimeShell}
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        unset NIX_STORE NIX_REMOTE
        "${defPkgs.nix}/bin/nix";
      '');
    };

    devShell = with defPkgs; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ defPkgs.nix jq ];
      shellHook = ''
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        unset NIX_STORE NIX_REMOTE
        unset TMP TMPDIR TEMPDIR TEMP
        NIX_PATH=
        ${lib.concatMapStrings (f: ''
          NIX_PATH+=:${toString f}=${toString flakes.${f}}
        '') (builtins.attrNames flakes) }
        export NIX_PATH

      '';
    };

  })) // {
    overlay = final: prev: (import ./overlay.nix final prev) //{
      nix_spartan = defaultPkgsFor.x86_64-linux.nix;
    };
  };
}
