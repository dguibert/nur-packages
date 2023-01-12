{
  description = "A flake for building my envs";
  # install chemacs2 (https://github.com/plexus/chemacs2)
  # and
  # emacs --with-profile "((user-emacs-directory . \"$PWD/emacs.d\"))"

  inputs.upstream.url = "path:..";
  inputs.nixpkgs.follows = "upstream/nixpkgs";
  inputs.nix.follows = "upstream/nix";
  inputs.flake-utils.follows = "upstream/flake-utils";

  inputs.emacs-src.url = "github:emacs-mirror/emacs/emacs-29";
  inputs.emacs-src.flake = false;
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";
  inputs.emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-utils.url      = "github:numtide/flake-utils";

  outputs = { self, upstream
            ,  nixpkgs
            , flake-utils
            , ...
            }@inputs: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  upstream.legacyPackages.${system}.overlays ++ [
          inputs.emacs-overlay.overlay
          self.overlays.default
        ];
        config.allowUnfree = true;
    };

    in (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
       let pkgs = nixpkgsFor system; in
       rec {

    packages.my-emacs = pkgs.my-emacs;

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
    overlays.default = final: prev: 
      (import ./overlay.nix final prev) //
      ({
        emacsPgtk = (prev.emacsPgtk.override {
        }).overrideAttrs (old : {
          name = "emacs-pgtk";
          version = inputs.emacs-src.shortRev;
          src = inputs.emacs-src;
        });
      });
  };
}

