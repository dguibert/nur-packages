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

    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    base16-nix           = { url  = "github:atpotts/base16-nix"; flake=false; };
    # For accessing `deploy-rs`'s utility Nix functions
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs
            , nur_dguibert
            , nix
            , flake-utils
            , home-manager
            , base16-nix
            , deploy-rs
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
            overlays.aocc
            overlays.flang
            overlays.intel-compilers
            overlays.arm
            overlays.pgi
            (import ../../envs/overlay.nix nixpkgs)
            self.overlay
          ];
          config.allowUnfree = true;
        };

    overlays = import ../../overlays;

    NIX_CONF_DIR_fun = pkgs: let
      nixConf = pkgs.writeTextDir "opt/nix.conf" ''
        max-jobs = 8
        cores = 0
        sandbox = false
        auto-optimise-store = true
        require-sigs = true
        trusted-users = nixBuild dguibert
        allowed-users = *

        system-features = recursive-nix nixos-test benchmark big-parallel kvm
        sandbox-fallback = false

        keep-outputs = true       # Nice for developers
        keep-derivations = true   # Idem
        extra-sandbox-paths = /opt/intel/licenses=/home/dguibert/nur-packages/secrets?
        experimental-features = nix-command flakes ca-references recursive-nix

        extra-platforms = armv7l-linux i686-linux
        builders = ssh://spartan501; ssh://spartan501 x86_64-linux - 16 1 benchmark,big-parallel,recursive-nix
      '';
    in
      "${nixConf}/opt";

  in (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
       let pkgs = nixpkgsFor system;
           defPkgs = defaultPkgsFor system;
       in rec {

    legacyPackages = pkgs;

    defaultApp = apps.nix;
    apps.nix = flake-utils.lib.mkApp { drv = pkgs.writeScriptBin "nix-spartan" (with defPkgs; let
        name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
        NIX_CONF_DIR = NIX_CONF_DIR_fun pkgs;
      # https://gist.githubusercontent.com/cleverca22/bc86f34cff2acb85d30de6051fa2c339/raw/03a36bbced6b3ae83e46c9ea9286a3015e8285ee/doit.sh
      # NIX_REMOTE=local?root=/home/clever/rootfs/
      # NIX_CONF_DIR=/home/$X/etc/nix
      # NIX_LOG_DIR=/home/$X/nix/var/log/nix
      # NIX_STORE=/home/$X/nix/store
      # NIX_STATE_DIR=/home/$X/nix/var
      # nix-build -E 'with import <nixpkgs> {}; nix.override { storeDir = "/home/'$X'/nix/store"; stateDir = "/home/'$X'/nix/var"; confDir = "/home/'$X'/etc"; }'
      in ''
        #!${runtimeShell}
        set -x
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        ##export NIX_REMOTE=local?root=$HOME/${name}/
        ###FIXME export NIX_CONF_DIR=${nixStore}/etc
        ##export NIX_CONF_DIR=${NIX_CONF_DIR}
        ##export NIX_LOG_DIR=${nixStore}/var/log/nix
        export NIX_STORE=${nixStore}/store
        ##export NIX_STATE_DIR=${nixStore}/var
        export PATH=${defPkgs.nix}/bin:$PATH
        $@
      '');
    };

    devShell = with defPkgs; mkEnv rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      buildInputs = [ defPkgs.nix jq
        deploy-rs.packages.${system}.deploy-rs
      ];
      shellHook = ''
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        ##export NIX_REMOTE=local?root=$HOME/${name}/
        ###export NIX_CONF_DIR=${nixStore}/etc
        ##export NIX_LOG_DIR=${nixStore}/var/log/nix
        export NIX_STORE=${nixStore}/store
        ##export NIX_STATE_DIR=${nixStore}/var
        unset TMP TMPDIR TEMPDIR TEMP
        unset NIX_PATH

      '';
      NIX_CONF_DIR = NIX_CONF_DIR_fun pkgs;
    };

    homeConfigurations.home-bguibertd = home-manager.lib.homeManagerConfiguration {
      username = "bguibertd";
      homeDirectory = "/home_nfs_robin_ib/bguibertd";
      inherit system pkgs;
      configuration = { lib, ... }: {
        imports = [ (import "${base16-nix}/base16.nix")
          (import ./home-dguibert.nix)
        ];
        _module.args.pkgs = lib.mkForce pkgs;
      };
    };


  })) // {
    overlay = final: prev: (import ./overlay.nix final prev) //{
      nix_spartan = defaultPkgsFor.x86_64-linux.nix;
    };

    deploy.nodes.spartan = {
      hostname = "spartan";
      profiles.software = rec {
        user = "bguibertd";
        sshUser = "bguibertd";
        path = deploy-rs.lib.x86_64-linux.activate.custom self.legacyPackages.x86_64-linux.slash_software._modulefiles
               "rm -f ~/software; ln -sfd ${profilePath} ~/software";
        profilePath = "${self.legacyPackages.x86_64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/software";
      };
      profiles.bguibertd-hm = {
        user = "bguibertd";
        sshUser = "bguibertd";
        path = deploy-rs.lib.x86_64-linux.activate.custom self.homeConfigurations.x86_64-linux.home-bguibertd.activationPackage
               "env NIX_STATE_DIR=${self.legacyPackages.x86_64-linux.nixStore}/var/nix ./activate";
        profilePath = "${self.legacyPackages.x86_64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/hm";
      };
    };
  };
}
