{ versions ? import ./versions.nix
, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
#, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
#, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
, overlays_ ? []
#, overlays_ ? [ (import ./overlays/local-genji.nix) ]
, system ? builtins.currentSystem

, pkgs ? import nixpkgs {
    config = import ./config.nix;
    overlays = let
      overlays' = import ./overlays;
    in [
      overlays'.default
      overlays'.aocc
      overlays'.flang
      overlays'.intel-compilers
      #overlays.arm
      overlays'.pgi
      overlays'.local
    ] ++ overlays_;
  }
}:
pkgs
