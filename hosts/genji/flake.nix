{
  description = "A flake for building my NUR packages on GENJI";

  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs = {
    nixpkgs.url          = "github:dguibert/nixpkgs/pu-cluster";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    base16-nix           = { url  = "github:atpotts/base16-nix"; flake=false; };
    # For accessing `deploy-rs`'s utility Nix functions
    deploy-rs.url = "github:dguibert/deploy-rs/pu";
    #deploy-rs.inputs.naersk.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nxsession.url              = "github:dguibert/nxsession";
  };

  outputs = { self, nixpkgs
            , nix
            , flake-utils
            , home-manager
            , base16-nix
            , deploy-rs
            , ...
            }@inputs: let

      # Memoize nixpkgs for different platforms for efficiency.
      defaultPkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays =  [
            overlays.default
            nix.overlay
            deploy-rs.overlay
            (final: prev: {
              nixStore = (self.overlay final prev).nixStore;
              nix = prev.nix.overrideAttrs (attrs: {
                doCheck = false;
                doInstallCheck=false;
              });
            })
          ];
          config.allowUnfree = true;
        };
      nixpkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays =  [
            nix.overlay
            deploy-rs.overlay
            overlays.default
            overlays.aocc
            overlays.flang
            overlays.intel-compilers
            overlays.arm
            overlays.pgi
            (import ../../envs/overlay.nix nixpkgs)
            (import ../../emacs/overlay.nix)
            self.overlay
            inputs.nxsession.overlay
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
        system-features = recursive-nix nixos-test benchmark big-parallel gccarch-x86-64
        #extra-platforms = i686-linux aarch64-linux

        builders = @/tmp/nix--home_nfs-bguibertd-machines
      '';
    in
      "${nixConf}/opt";

  in (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
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
        export NIX_STORE=${nixStore}/store
        export PATH=${defPkgs.nix}/bin:$PATH
        $@
      '');
    };

    devShell = with defPkgs; mkShell rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      ENVRC = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      nativeBuildInputs = [ defPkgs.nix jq
        deploy-rs.packages.${system}.deploy-rs
      ];
      shellHook = ''
        export ENVRC=${name}
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        export NIX_STORE=${nixStore}/store
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
        imports = [
         ({ config, pkgs, lib, ...}: {
           nixpkgs.overlays = [
             nix.overlay
             (import ./overlay.nix)
             (final: prev: {
               pinentry = prev.pinentry.override { enabledFlavors = [ "curses" "tty" ]; };
             })
           ];
           services.gpg-agent.pinentryFlavor = lib.mkForce "curses";
           home.packages = with pkgs; [
             pkgs.nix
           ];
           programs.bash.enable = true;
           programs.bash.profileExtra = ''
             if [ -e $HOME/.home-$(uname -m)/.profile ]; then
               source $HOME/.home-$(uname -m)/.profile
             fi
           '';
           programs.bash.bashrcExtra = ''
             if [ -e $HOME/.home-$(uname -m) ]; then
                 if [ -n "$HOME" ] && [ -n "$USER" ]; then

                     # Set up the per-user profile.
                     # This part should be kept in sync with nixpkgs:nixos/modules/programs/shell.nix

                     NIX_LINK=$HOME/.home-$(uname -m)/.nix-profile

                     # Set up environment.
                     # This part should be kept in sync with nixpkgs:nixos/modules/programs/environment.nix
                     export NIX_PROFILES="/home_nfs/bguibertd/nix/var/nix/profiles/default $NIX_LINK"

                     # Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
                     if [ -e /etc/ssl/certs/ca-certificates.crt ]; then # NixOS, Ubuntu, Debian, Gentoo, Arch
                          export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
                     elif [ -e /etc/ssl/ca-bundle.pem ]; then # openSUSE Tumbleweed
                          export NIX_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem
                     elif [ -e /etc/ssl/certs/ca-bundle.crt ]; then # Old NixOS
                          export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
                     elif [ -e /etc/pki/tls/certs/ca-bundle.crt ]; then # Fedora, CentOS
                          export NIX_SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt
                     elif [ -e "$NIX_LINK/etc/ssl/certs/ca-bundle.crt" ]; then # fall back to cacert in Nix profile
                          export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ssl/certs/ca-bundle.crt"
                     elif [ -e "$NIX_LINK/etc/ca-bundle.crt" ]; then # old cacert in Nix profile
                          export NIX_SSL_CERT_FILE="$NIX_LINK/etc/ca-bundle.crt"
                     fi

                     if [ -n "''${MANPATH-}" ]; then
                         export MANPATH="$NIX_LINK/share/man:$MANPATH"
                     fi

                     export PATH="$NIX_LINK/bin:$PATH"
                     unset NIX_LINK
                 fi
             else
                 if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
                   source $HOME/.nix-profile/etc/profile.d/nix.sh
                 fi
                 export NIX_IGNORE_SYMLINK_STORE=1 # aloy
             fi

             export NIX_IGNORE_SYMLINK_STORE=1 # aloy

             source $HOME/.home-$(uname -m)/.bashrc
           '';
           home.file.".inputrc".text = ''
             set show-all-if-ambiguous on
             set visible-stats on
             set page-completions off
             # https://git.suckless.org/st/file/FAQ.html
             set enable-keypad on
             # http://www.caliban.org/bash/
             #set editing-mode vi
             #set keymap vi
             #Control-o: ">&sortie"
             "\e[A": history-search-backward
             "\e[B": history-search-forward
             "\e[1;5A": history-search-backward
             "\e[1;5B": history-search-forward

             # Arrow keys in keypad mode
             "\C-[OA": history-search-backward
             "\C-[OB": history-search-forward
             "\C-[OC": forward-char
             "\C-[OD": backward-char

             # Arrow keys in ANSI mode
             "\C-[[A": history-search-backward
             "\C-[[B": history-search-forward
             "\C-[[C": forward-char
             "\C-[[D": backward-char

             # mappings for Ctrl-left-arrow and Ctrl-right-arrow for word moving
             "\e[1;5C": forward-word
             "\e[1;5D": backward-word
             #"\e[5C": forward-word
             #"\e[5D": backward-word
             "\e\e[C": forward-word
             "\e\e[D": backward-word

             $if mode=emacs

             # for linux console and RH/Debian xterm
             "\e[1~": beginning-of-line
             "\e[4~": end-of-line
             "\e[5~": beginning-of-history
             "\e[6~": end-of-history
             "\e[7~": beginning-of-line
             "\e[3~": delete-char
             "\e[2~": quoted-insert
             "\e[5C": forward-word
             "\e[5D": backward-word
             "\e\e[C": forward-word
             "\e\e[D": backward-word
             "\e[1;5C": forward-word
             "\e[1;5D": backward-word

             # for rxvt
             "\e[8~": end-of-line

             # for non RH/Debian xterm, can't hurt for RH/DEbian xterm
             "\eOH": beginning-of-line
             "\eOF": end-of-line

             # for freebsd console
             "\e[H": beginning-of-line
             "\e[F": end-of-line
             $endif
           '';

           # mimeapps.list
           # https://github.com/bobvanderlinden/nix-home/blob/master/home.nix
           home.keyboard.layout = "fr";


         })
        ];
        _module.args.pkgs = lib.mkForce pkgs;
      };
    };

    homeConfigurations.home-bguibertd-x86_64 = home-manager.lib.homeManagerConfiguration {
      username = "bguibertd";
      homeDirectory = "/home_nfs_robin_ib/bguibertd/.home-x86_64";
      inherit system pkgs;
      configuration = { lib, ... }: {
        imports = [ (import "${base16-nix}/base16.nix")
          (import ./home-dguibert.nix)
        ];
        _module.args.pkgs = lib.mkForce pkgs;
      };
    };

    homeConfigurations.home-bguibertd-aarch64 = home-manager.lib.homeManagerConfiguration {
      username = "bguibertd";
      homeDirectory = "/home_nfs_robin_ib/bguibertd/.home-aarch64";
      inherit system pkgs;
      configuration = { lib, ... }: {
        imports = [ (import "${base16-nix}/base16.nix")
          (import ./home-dguibert.nix)
        ];
        _module.args.pkgs = lib.mkForce pkgs;
      };
    };

  })) // {
    overlay = final: prev: import ./overlay.nix final prev;

    deploy.nodes.genji = {
      hostname = "genji";
      #profiles.software = rec {
      #  user = "bguibertd";
      #  sshUser = "bguibertd";
      #  path = deploy-rs.lib.x86_64-linux.activate.custom self.legacyPackages.x86_64-linux.slash_software._modulefiles
      #         "rm -f ~/software; ln -sfd ${profilePath} ~/software";
      #  profilePath = "${self.legacyPackages.x86_64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/software";
      #};
      profilesOrder = [
        "hm-bguibertd-x86_64"
        #"hm-bguibertd-aarch64"
        "hm-bguibertd"
      ];
      profiles.hm-bguibertd = {
        user = "bguibertd";
        sshUser = "bguibertd";
        path = (nixpkgsFor "x86_64-linux").deploy-rs.lib.activate.custom self.homeConfigurations.x86_64-linux.home-bguibertd.activationPackage
               "env NIX_STATE_DIR=${self.legacyPackages.x86_64-linux.nixStore}/var/nix HOME_MANAGER_BACKUP_EXT=bak ./activate";
        profilePath = "${self.legacyPackages.x86_64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/hm";
      };
      profiles.hm-bguibertd-x86_64 = {
        user = "bguibertd";
        sshUser = "bguibertd";
        path = (nixpkgsFor "x86_64-linux").deploy-rs.lib.activate.custom self.homeConfigurations.x86_64-linux.home-bguibertd-x86_64.activationPackage
               "env NIX_STATE_DIR=${self.legacyPackages.x86_64-linux.nixStore}/var/nix HOME=${self.homeConfigurations.x86_64-linux.home-bguibertd-x86_64.config.home.homeDirectory} ./activate";
        profilePath = "${self.legacyPackages.x86_64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/hm-x86_64";
      };
      profiles.hm-bguibertd-aarch64 = {
        user = "bguibertd";
        sshUser = "bguibertd";
        path = (nixpkgsFor "x86_64-linux").deploy-rs.lib.activate.custom self.homeConfigurations.aarch64-linux.home-bguibertd-aarch64.activationPackage
               "env NIX_STATE_DIR=${self.legacyPackages.aarch64-linux.nixStore}/var/nix HOME=${self.homeConfigurations.aarch64-linux.home-bguibertd-aarch64.config.home.homeDirectory} ./activate";
        profilePath = "${self.legacyPackages.aarch64-linux.nixStore}/var/nix/profiles/per-user/bguibertd/hm-aarch64";
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
