{ config, withSystem, ... }:
{
  perSystem = {config, self', inputs', pkgs, system, ...}: {
    devShells.nix = pkgs.mkShell {
      name = "nix";
      ENVRC = "nix";
      buildInputs = with pkgs; [ pkgs.nix jq ];
    };
  };
}
