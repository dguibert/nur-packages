final: prev: with prev; let
  # https://gist.github.com/grahamc/2daa060dce38ad18ddfa7927e1b1a1b3
  #emacsPackaging = pkgs.emacs27-nox.pkgs;
  emacsPackaging = emacs27.pkgs;

  my-texlive = (texlive.combine {
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
      #evil-magit
      evil-matchit
      evil-numbers
      evil-surround
      evil-visualstar

      direnv
      notmuch

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
      visual-fill-column

      org-roam
      org-roam-bibtex

      org-noter
      org-noter-pdftools
      org-pdftools
    ]) ++ [
      notmuch   # From main packages set
      ripgrep

      xclip
      #my-mode
    ]);

in {
  inherit my-texlive;
  inherit my-emacs;
}
