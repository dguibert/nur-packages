{ lib, inputs, outputs, system, ... }@args: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.self.overlays.default
      inputs.self.overlays.cluster
    ];
    config.replaceStdenv = import ../stdenv.nix;
  };
in
{
  zlib = pkgs.zlib;
}
