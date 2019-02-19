{ pkgs }:

with pkgs.lib; pkgs.lib // {
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
  compose = list: fix (builtins.foldl' (flip extends) (self: pkgs) list);

  composeOverlays = foldl' composeExtensions (self: super: {});

  makeExtensible' = pkgs: list: builtins.foldl' /*op nul list*/
    (o: f: o.extend f) (makeExtensible (self: pkgs)) list;

  mkEnv = { name ? "env"
          , buildInputs ? []
          , ...
        }@args: let name_=name;
                    args_ = builtins.removeAttrs args [ "name" "buildInputs" "shellHook" ];
        in pkgs.stdenv.mkDerivation (rec {
    name = "${name_}-env";
    phases = [ "buildPhase" ];
    postBuild = "ln -s ${env} $out";
    env = pkgs.buildEnv { name = name; paths = buildInputs; };
    inherit buildInputs;
    shellHook = ''
      export ENVRC=${name_}
      source ~/.bashrc
    '' + (args.shellHook or "");
  } // args_);
}

