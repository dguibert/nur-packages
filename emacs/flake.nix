{
  description = "A flake for building my envs";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu";
  inputs.nix.url              = "github:dguibert/nix/pu";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nix-ccache.url       = "github:dguibert/nix-ccache/pu";
  #inputs.nix-ccache.inputs.nixpkgs.follows = "nixpkgs";

  inputs.flake-utils.url      = "github:numtide/flake-utils";

  #inputs.nur_dguibert_envs.url= "github:dguibert/nur-packages/pu?dir=envs";
  inputs.nur_dguibert_envs.url= "git+file:///home/dguibert/nur-packages?dir=envs";
  inputs.nur_dguibert_envs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert_envs.inputs.nix.follows = "nix";
  inputs.nur_dguibert_envs.inputs.nix.inputs.nixpkgs.follows = "nixpkgs";


  outputs = { self, nixpkgs
            , nix
            #, nix-ccache
            , nur_dguibert_envs
            , flake-utils
            , ...
            }@flakes: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          nix.overlay
          nur_dguibert_envs.overlay
          nur_dguibert_envs.overlays.extra-builtins
          self.overlay
        ];
        config.allowUnfree = true;
        config.psxe.licenseFile = "none"; #<secrets/lic>;
    };

  in (flake-utils.lib.eachDefaultSystem (system:
       let pkgs = nixpkgsFor system; in
       rec {

    legacyPackages = pkgs;

    devShell = pkgs.mkEnv {
      name = "emacs";
      buildInputs = with pkgs; let
        # https://gist.github.com/grahamc/2daa060dce38ad18ddfa7927e1b1a1b3
        #emacsPackaging = pkgs.emacs27-nox.pkgs;
        emacsPackaging = pkgs.emacs27.pkgs;

        my-texlive = with pkgs; (texlive.combine {
          inherit (texlive) scheme-medium
            wrapfig
            capt-of
          ; });

        emacsWithPackages = emacsPackaging.emacsWithPackages;
        # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.elpaPackages
        # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.melpaPackages
        # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.melpaStablePackages
        # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.orgPackages
        my-emacs = emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
            #magit          # ; Integrate git <C-x g>
            #zerodark-theme # ; Nicolas' theme
          ]) ++ (with epkgs.melpaPackages; [
            #undo-tree      # ; <C-x u> to show the undo tree
            #zoom-frm       # ; increase/decrease font size for all buffers %lt;C-x C-+>
          ]) ++ (with epkgs.elpaPackages; [
            #auctex         # ; LaTeX mode
            #beacon         # ; highlight my cursor when scrolling
            #nameless       # ; hide current package name everywhere in elisp code
          ]) ++ (with epkgs; [
            use-package
            use-package-ensure-system-package
            nix-mode
            all-the-icons-ivy
            doom-modeline
            doom-themes

            which-key

            evil
            evil-leader
            evil-collection
            evil-magit
            evil-matchit
            evil-numbers
            evil-surround
            evil-visualstar

            direnv
            notmuch

            ivy
            org-bullets
            rainbow-delimiters

            general
          ]) ++ [
            pkgs.notmuch   # From main packages set
            #my-mode
          ]);

      in [
        my-texlive
        my-emacs
      ];
    };
  })) // rec {
    overlay = final: prev: {
    };
  };
}

