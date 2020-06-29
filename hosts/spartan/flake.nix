{
  description = "A flake for building my NUR packages on SPARTAN";

  inputs = {
    home-manager. url    = "github:dguibert/home-manager/pu";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hydra.url            = "github:dguibert/hydra/pu";
    hydra.inputs.nix.follows = "nix";
    hydra.inputs.nixpkgs.follows = "nixpkgs";

    nixops.url           = "github:dguibert/nixops/pu";
    nixops.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url          = "github:dguibert/nixpkgs/pu";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    nur_dguibert.url     = "github:dguibert/nur-packages/pu";
    nur_dguibert.inputs.nix.follows = "nix";
    #nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
    #nur_dguibert_envs.url= "/home/dguibert/nur-packages?dir=envs";
    terranix             = { url = "github:mrVanDalo/terranix"; flake=false; };
    #"nixos-18.03".url   = "github:nixos/nixpkgs-channels/nixos-18.03";
    #"nixos-18.09".url   = "github:nixos/nixpkgs-channels/nixos-18.09";
    #"nixos-19.03".url   = "github:nixos/nixpkgs-channels/nixos-19.03";
    base16-nix           = { url  = "github:atpotts/base16-nix"; flake=false; };
    NUR                  = { url  = "github:nix-community/NUR"; flake=false; };
    gitignore            = { url  = "github:hercules-ci/gitignore"; flake=false; };
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
      defaultPkgsFor = forAllSystems (system:
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
    overlay = final: prev: (import ./spartan-overlay.nix final prev) //{
      nix_spartan = defaultPkgsFor.x86_64-linux.nix;
    };

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

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) nix nix_spartan;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.nix);

    defaultApp.x86_64-linux = {
      type = "app";
      program = "${defaultPkgsFor.x86_64-linux.nix}/bin/nix";
    };
  };
}
