{ pkgs, ... }:
pkgs.mkShell {
  name = "nix";
  ENVRC = "nix";
  buildInputs = with pkgs; [ pkgs.nix jq ];
}
