
{
  epoch = 201909;

  description = "A flake for building my NUR packages on SPARTAN";

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
            self.overlay
          ];
          config.allowUnfree = true;
        }
      );


    overlays = import ../../overlays;

  in rec {
    overlay = import ./spartan-overlay.nix;

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

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) nix;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.nix);


  };
}
