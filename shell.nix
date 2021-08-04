{ pkgs ? import <nixpkgs> { }
, ssh-to-pgp
, sops-import-keys-hook
}:
with pkgs;

mkShell rec {
  name = "nur";
  ENVRC = "nur";

  # imports all files ending in .asc/.gpg and sets $SOPS_PGP_FP.
  sopsPGPKeyDirs = [
  #  #"./keys/hosts"
  #  #"./keys/users"
  ];
  # Also single files can be imported.
  sopsPGPKeys = [
    "./keys/hosts/titan.asc"
    "./keys/hosts/rpi41.asc"
    "./keys/hosts/rpi31.asc"
    "./keys/hosts/t580.asc"
    "./keys/users/dguibert.asc"
  ];
  buildInputs = [
    sops-import-keys-hook
    ssh-to-pgp

    jq
  ];
  shellHook = ''
    unset NIX_INDENT_MAKE
    unset IN_NIX_SHELL NIX_REMOTE
    unset TMP TMPDIR

    export SHELL=${bashInteractive}/bin/bash

  '';
}
