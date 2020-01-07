
{
  epoch = 201909;

  description = "A flake for building my NUR packages on ALOY";

  inputs = {
    home-manager         = { uri = "github:dguibert/home-manager/pu"; flake=false; };
    hydra.uri            = "github:dguibert/hydra/pu";
    nixops.uri           = "github:dguibert/nixops/pu";
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
    nur_dguibert.uri     = "github:dguibert/nur-packages/dg-remote-urls";
    terranix             = { uri = "github:mrVanDalo/terranix"; flake=false; };
    #"nixos-18.03".uri   = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".uri   = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".uri   = "github:nixos/nixpkgs-channels/nixos-19.03";
    base16-nix           = { uri  = "github:atpotts/base16-nix"; flake=false; };
    NUR                  = { uri  = "github:nix-community/NUR"; flake=false; };
    gitignore            = { uri  = "github:hercules-ci/gitignore"; flake=false; };
  };

  outputs = { self, nixpkgs
            , nur_dguibert
            , base16-nix
            , NUR
            , gitignore
            , home-manager
            , terranix
            , hydra
            , nix
            , nixops
            }@flakes: let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays =  [
            overlays.default
            nix.overlay
            my-nix-overlay
            self.overlay
          ];
          config.allowUnfree = true;
        }
      );


    overlays = import ../../overlays;
    my-nix-overlay = import ../../nix/nix-overlay.nix;

  in rec {
    overlay = final: prev: {
      nixStore = "/home_nfs/bguibertd/nix";

      p11-kit = prev.p11-kit.overrideAttrs (attrs: {
        doCheck = false;
      });
      go_bootstrap = prev.go_bootstrap.overrideAttrs (attrs: {
        doCheck = false;
        installPhase = ''
          mkdir -p "$out/bin"
          export GOROOT="$(pwd)/"
          export GOBIN="$out/bin"
          export PATH="$GOBIN:$PATH"
          cd ./src
          ./make.bash
        '';
      });
      go_1_10 = prev.go_1_10.overrideAttrs (attrs: {
        doCheck = false;
        installPhase = ''
          mkdir -p "$out/bin"
          export GOROOT="$(pwd)/"
          export GOBIN="$out/bin"
          export PATH="$GOBIN:$PATH"
          cd ./src
          ./make.bash
        '';
      });
      go_1_11 = prev.go_1_11.overrideAttrs (attrs: {
        doCheck = false;
      });
      go_1_13 = prev.go_1_13.overrideAttrs (attrs: {
        doCheck = false;
      });
      libuv = prev.libuv.overrideAttrs (attrs: {
        doCheck = false;
      });

      jobs = prev.jobs.override {
        admin_scripts_dir = "/home_nfs/script/admin";
        #scheduler = prev.jobs.scheduler_slurm;
      };
      fetchannex = { file ? builtins.baseNameOf url
                   , repo ? "${builtins.getEnv "HOME"}/nur-packages/downloads"
                   , name ? builtins.baseNameOf url
                   , recursiveHash ? false
                   , sha256
                   , url
      }: prev.requireFile {
        inherit name sha256 url;
        hashMode = if recursiveHash then "recursive" else "flat";
        message = ''
         Unfortunately, we cannot download file ${name} automatically.
         either:
           - go to ${url} to download it yourself
           - get it to the git annexed repo ${repo}

         and add it to the Nix store
           nix-store --add-fixed sha256 ${repo}/${name}

        '';
      };
      slurm = prev.slurm_17_02_11;

      pythonOverrides = prev.lib.composeOverlays [
        (prev.pythonOverrides or (_:_: {}))
        (python-final: python-prev: {
          pyslurm = python-prev.pyslurm_17_11_12.override { slurm=final.slurm; };
        })
      ];


    };

    devShell.x86_64-linux = with nixpkgsFor.x86_64-linux; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ nixpkgsFor.x86_64-linux.nix jq ];
      shellHook = ''
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        unset NIX_STORE NIX_DAEMON
        NIX_PATH=
        ${lib.concatMapStrings (f: ''
          NIX_PATH+=:${toString f}=${toString flakes.${f}}
        '') (builtins.attrNames flakes) }
        export NIX_PATH

      '';
    };

  };
}
