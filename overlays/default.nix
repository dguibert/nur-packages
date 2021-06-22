rec {
  default = import ../overlay.nix;
  local = final: prev: if (builtins.pathExists ./local.nix) then (import (./local.nix)) final prev else {};

  aocc = import ./aocc-overlay;
  flang = import ./flang-overlay;
  intel-compilers = import ./intel-compilers-overlay;
  intel-oneapi = import ./intel-oneapi;
  arm = import ./arm-overlay;
  pgi = import ./pgi-overlay;

  emacs = import ../emacs/overlay.nix;
  extra-builtins = import ../extra-builtins/overlay.nix;
}

