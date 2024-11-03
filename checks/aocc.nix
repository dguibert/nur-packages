{
  config,
  withSystem,
  inputs,
  self,
  ...
}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: let
    pkgs' = import inputs.nixpkgs {
      inherit system;
      overlays = [
        self.overlays.aocc-overlay
      ];
    };
    aoccPkgs = import inputs.nixpkgs {
      inherit system;
      config.replaceStdenv = {pkgs, ...}: pkgs'.aoccPackages_500.stdenv;
    };
  in {
    checks.aocc-stdenv = pkgs.aoccPackages_500.stdenv;
    checks.aocc-zlib = aoccPkgs.zlib;
    #checks.aocc-zlib = pkgs.zlib;
  };
}
