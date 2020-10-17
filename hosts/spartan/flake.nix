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
      # https://gist.githubusercontent.com/cleverca22/bc86f34cff2acb85d30de6051fa2c339/raw/03a36bbced6b3ae83e46c9ea9286a3015e8285ee/doit.sh
      # NIX_REMOTE=local?root=/home/clever/rootfs/
      # NIX_CONF_DIR=/home/$X/etc/nix
      # NIX_LOG_DIR=/home/$X/nix/var/log/nix
      # NIX_STORE=/home/$X/nix/store
      # NIX_STATE_DIR=/home/$X/nix/var
      # nix-build -E 'with import <nixpkgs> {}; nix.override { storeDir = "/home/'$X'/nix/store"; stateDir = "/home/'$X'/nix/var"; confDir = "/home/'$X'/etc"; }'
      in ''
        #!${runtimeShell}
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        export NIX_REMOTE=local?root=$HOME/rootfs/
        export NIX_CONF_DIR=${nixStore}/etc
        export NIX_LOG_DIR=${nixStore}/var/log/nix
        export NIX_STORE=${nixStore}/store
        export NIX_STATE_DIR=${nixStore}/var
        "${defPkgs.nix}/bin/nix";
      '');
    };

    devShell = with defPkgs; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ defPkgs.nix jq ];
      shellHook = ''
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        export NIX_REMOTE=local?root=$HOME/rootfs/
        #export NIX_CONF_DIR=${nixStore}/etc
        export NIX_LOG_DIR=${nixStore}/var/log/nix
        export NIX_STORE=${nixStore}/store
        export NIX_STATE_DIR=${nixStore}/var
        unset TMP TMPDIR TEMPDIR TEMP
        unset NIX_PATH

      '';
      NIX_CONF_DIR = let
        current = pkgs.lib.optionalString (builtins.pathExists /etc/nix/nix.conf)
          (builtins.readFile /etc/nix/nix.conf);

        nixConf = pkgs.writeTextDir "opt/nix.conf" ''
          ${current}
          experimental-features = nix-command flakes ca-references
        '';
      in
        "${nixConf}/opt";
    };

  })) // {
    overlay = final: prev: (import ./overlay.nix final prev) //{
      nix_spartan = defaultPkgsFor.x86_64-linux.nix;
    };
  };
}
