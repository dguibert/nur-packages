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
      overlays =
        pkgs.overlays
        ++ [
          self.overlays.aocc-overlay
        ];
    };
    aoccPkgs = import inputs.nixpkgs {
      inherit system;
      overlays = pkgs.overlays;
      #config.replaceStdenv = {pkgs, ...}: pkgs'.aoccPackages_320.stdenv;
      config.replaceStdenv = {pkgs, ...}: pkgs'.aoccPackages_500.stdenv;
    };
  in {
    #checks.aocc-stdenv = pkgs.aoccPackages_500.stdenv;
    checks.aocc-stdenv = aoccPkgs.stdenv;
    checks.aocc-hello = aoccPkgs.hello;
    # TODO why this is needed? otherwise gcc is used
    checks.aocc-zlib-320 = aoccPkgs.zlib.override {stdenv = pkgs.aoccPackages_320.stdenv;};
    checks.aocc-zlib-420 = aoccPkgs.zlib.override {stdenv = pkgs.aoccPackages_420.stdenv;};
    checks.aocc-zlib = aoccPkgs.zlib.override {stdenv = aoccPkgs.stdenv;};
    checks.aocc-hello-override = pkgs.hello.override {stdenv = aoccPkgs.stdenv;};
    checks.aocc-zlib-override = pkgs.zlib.override {stdenv = aoccPkgs.stdenv;};
  };
}
