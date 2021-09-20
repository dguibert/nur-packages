final: prev: with prev; let
  # https://gist.github.com/grahamc/2daa060dce38ad18ddfa7927e1b1a1b3
  #emacsPackaging = pkgs.emacs27-nox.pkgs;
  emacsPackaging = emacs27.pkgs;

  my-texlive = (texlive.combine {
    inherit (texlive) scheme-medium
      wrapfig
      capt-of

      moderncv
      biblatex
    ; });


  overrides = self: super: {
    org-cv = self.trivialBuild {
      pname = "org-cv";
      version = "0.0.1";
      src = fetchFromGitLab {
        owner = "Titan-C";
        repo = "org-cv";
        rev = "24bcd82348d441d95c2c80fb8ef8b5d6d4b80d95";
        sha256 = "sha256-4jXttJUkmJbWvW+A0euLDV5Mzj9Pjar/No1ETndfln0=";
      };
      buildInputs = [ self.ox-hugo ];
    };
  };

  emacsWithPackages = emacsPackaging.emacsWithPackages;
  # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.elpaPackages
  # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.melpaPackages
  # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.melpaStablePackages
  # nix-env -f "<nixpkgs>" -qaP -A emacsPackages.orgPackages
  my-emacs = ((pkgs.emacsPackagesGen emacs27).overrideScope' overrides).emacsWithPackages
  #my-emacs = emacsWithPackages
    (epkgs: (with epkgs.melpaStablePackages; [
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
      #evil-magit
      evil-matchit
      evil-numbers
      evil-surround
      evil-visualstar

      direnv
      notmuch
      gnus-alias

      ivy
      ivy-rich
      org-bullets
      rainbow-delimiters

      general

      hydra

      projectile
      magit
      counsel-projectile

      org-download
      ob-async
      gnuplot
      visual-fill-column

      org-roam
      org-roam-bibtex

      org-noter
      org-ref

      cmake-mode

      all-the-icons

      org-contrib
      org-tree-slide

      org-cv
    ]) ++ [
      notmuch   # From main packages set
      ripgrep

      xclip
      #my-mode
      sqlite.bin
    ]);

in {
  inherit my-texlive;
  inherit my-emacs;
}
