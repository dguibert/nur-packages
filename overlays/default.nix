rec {
  default = import ../overlay.nix;
  local = final: prev: if (builtins.pathExists ./local.nix) then (import (./local.nix)) final prev else {};

  aocc = import ./aocc-overlay;
  flang = import ./flang-overlay;
  intel-compilers = import ./intel-compilers-overlay;
  arm = import ./arm-overlay;
  pgi = import ./pgi-overlay;
}

