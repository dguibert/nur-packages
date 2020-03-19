
{
  epoch = 201909;

  description = "A flake for building my NUR packages on GENJI";

  inputs = {
    home-manager         = { uri = "github:dguibert/home-manager/pu"; flake=false; };
    hydra.uri            = "github:dguibert/hydra/pu";
    nixops.uri           = "github:dguibert/nixops/pu";
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.uri = "github:dguibert/nixpkgs/pu";
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
            self.overlay
          ];
          config.allowUnfree = true;
        }
      );


    overlays = import ../../overlays;

  in rec {
    overlay = import ./genji-overlay.nix;

    devShell.x86_64-linux = with nixpkgsFor.x86_64-linux; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ nixpkgsFor.x86_64-linux.nix jq ];
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

    packages = forAllSystems (system: with nixpkgsFor.${system}; {
      nix = nixpkgsFor.${system}.nix;
      job1 = (jobs.job1.override {
        name = "job1";
        jobImpl = jobs.sbatchJob;
        sbatch-job-name = "CEPP";
      }).submit;
      xpra-start = let
        config = (lib.evalModules {
          modules =
            (import "${nixpkgs}/nixos/modules/module-list.nix") ++ [
            ({ config, pkgs, ... }: {
              services.xserver.enable = true;
              services.xserver.display = null;
              services.xserver.displayManager.xpra.enable = true;
              services.xserver.displayManager.xpra.bindTcp = null;
              services.xserver.displayManager.xpra.pulseaudio = true;
              services.xserver.displayManager.xpra.extraOptions = [
                "--log-dir=$HOME/.xpra"
                "--socket-dirs=$HOME/.xpra"
                "--fake-xinerama=no"
              ];
              nixpkgs.system = system;
              nixpkgs.pkgs = nixpkgsFor.${system};
            })
            #<nixpkgs/nixos/modules/services/x11/display-managers/xpra.nix>
          ];
        }).config;
      in writeScript "launch-xpra" ''
        #!${bash}/bin/bash

        set -x
        ${config.services.xserver.displayManager.job.execCmd}
      '';
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.nix);


  };
}
