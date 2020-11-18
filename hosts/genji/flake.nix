
{
  epoch = 201909;

  description = "A flake for building my NUR packages on GENJI";

  inputs = {
    home-manager         = { uri = "github:dguibert/home-manager/pu"; flake=false; };
    nixpkgs.uri          = "github:dguibert/nixpkgs/pu";
    nix.uri              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    #"nixos-18.03".uri   = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".uri   = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".uri   = "github:nixos/nixpkgs-channels/nixos-19.03";
    gitignore            = { uri  = "github:hercules-ci/gitignore"; flake=false; };
  };

  outputs = { self, nixpkgs
            , gitignore
            , home-manager
            , nix
            }@flakes: let
      systems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      defaultPkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays =  [
            overlays.default
            nix.overlay
            (final: prev: {
              nixStore = "/home_nfs_robin_ib/bguibertd/nix";
            })
          ];
          config.allowUnfree = true;
        }
      );
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays =  [
            nix.overlay
            overlays.default
            self.overlay
          ];
          config.allowUnfree = true;
        }
      );


    overlays = import ../../overlays;

  in rec {
    overlay = import ./genji-overlay.nix;

    devShell.x86_64-linux = with defaultPkgsFor.x86_64-linux; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ defaultPkgsFor.x86_64-linux.nix jq ];
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
