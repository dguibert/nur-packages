{
  config,
  withSystem,
  inputs,
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
    # fails
    lib = pkgs.lib;

    stdenvStages = nixpkgs: system: import ../pkgs/stdenv-stages.nix;

    pkgs' = import "${inputs.nixpkgs}/pkgs/top-level/default.nix" {
      localSystem.system = system;
      overlays = [];
      config = {};
      #overlays = [
      #  (import ../overlays/default)
      #];
      #stdenvStages = builtins.trace "stdenvStages" import /home/dguibert/nur-packages-stdenv-stages/nixpkgs-copy/pkgs/stdenv;
      #stdenvStages = builtins.trace "stdenvStages" import ../pkgs/stdenv/linux pkgs.lib;
      stdenvStages = args: import ../pkgs/stdenv-stages.nix inputs.nixpkgs system;
    };
  in {
    checks.zlib = pkgs'.zlib;
    #infinite_recursion = if (builtins.tryEval (builtins.deepSeq pkgs'.zlib pkgs'.zlib)).success then throw "this should have failed with 'infinite recursion'" else null;
  };
}
