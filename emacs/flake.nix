{
  description = "A flake for building my envs";
  # install chemacs2 (https://github.com/plexus/chemacs2)
  # and
  # emacs --with-profile "((user-emacs-directory . \"$PWD/emacs.d\"))"

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nix-ccache.url       = "github:dguibert/nix-ccache/pu";
  #inputs.nix-ccache.inputs.nixpkgs.follows = "nixpkgs";

  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";

  inputs.flake-utils.url      = "github:numtide/flake-utils";

  outputs = { self, nixpkgs
            , nix
            #, nix-ccache
            , flake-utils
            , ...
            }@inputs: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          inputs.nix.overlay
          inputs.emacs-overlay.overlay
          overlays.default
          overlays.extra-builtins
          self.overlay
        ];
        config.allowUnfree = true;
        config.psxe.licenseFile = "none"; #<secrets/lic>;
    };

    overlays = import ../overlays;

  in (flake-utils.lib.eachDefaultSystem (system:
       let pkgs = nixpkgsFor system; in
       rec {

    legacyPackages = pkgs;

    devShell = pkgs.mkShell {
      name = "emacs";
      ENVRC = "emacs";
      CHEMACS_PROFILE="dev";
      buildInputs = with pkgs; let
      in [
        biber
        my-texlive
        my-emacs
        gnuplot

      ];
    };
  })) // rec {
    overlay = import ./overlay.nix;
  };
}

