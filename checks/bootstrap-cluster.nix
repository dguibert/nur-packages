{ lib, inputs, outputs, system, ... }@args: let
  # fails
  pkgs' = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.self.overlays.default
    ];
    config.replaceStdenv = import ../stdenv.nix;
  };

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
  #infinite_recursion = if (builtins.tryEval (builtins.deepSeq pkgs'.zlib pkgs'.zlib)).success then throw "this should have failed with 'infinite recursion'" else null;
}
