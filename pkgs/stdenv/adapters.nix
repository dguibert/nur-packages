/* This file extends <nipkg/pkgs/stdenv/adapters.nix> that contains various functions
   that take a stdenv and return a new stdenv with different behaviour, e.g. using a different
   C compiler or customized flags.
 */
pkgs:

rec {
  # https://stackoverflow.com/questions/42136197/how-to-override-compile-flags-for-a-single-package-in-nixos
  # https://github.com/NixOS/nixpkgs/issues/305
  extraNativeCflags = stdenv: import (pkgs.runCommand "cflags" {
     preferLocalBuild = true;
     #__noChroot = true; # '__noChroot' set, but that's not allowed when 'sandbox' is 'true'
     #hashChangingValue = builtins.readFile /some/system-dependent-file-that-doesn't-have-size-0 or builtins.currentTime;
     hashChangingValue = builtins.currentTime;
     buildInputs = [ stdenv.cc ];
   } ''
   mkdir $out
   echo "" | gcc -O3 -march=native -mtune=native -v -E - 2>&1 |grep cc1 |sed -r 's/.*? - -(.*)$/-\1/' > $out/flags
   echo "builtins.readFile ./flags" > $out/default.nix
  '');

  customFlags =
    {    flags ? "" # all flags (cflags, fflags, ldflags)
      , cflags ? ""
      , fflags ? ""
      ,ldflags ? ""
    }:
    pkg: pkg.overrideAttrs (attrs: {
    preConfigure = ''
      export CFLAGS="$CFLAGS ${flags} ${cflags}"
      export FFLAGS="$FFLAGS ${flags} ${fflags}"
      export FCFLAGS="$FCFLAGS ${flags} ${fflags}"
      export LDFLAGS="$LDFLAGS ${flags} ${ldflags}"
    '' + "${attrs.preConfigure or ""}";
  });

  customFlagsWithinStdEnv =
    {    flags ? "" # all flags (cflags, fflags, ldflags)
      , cflags ? ""
      , fflags ? ""
      ,ldflags ? ""
    }:
    stdenv: stdenv // {mkDerivation = args: stdenv.mkDerivation (args // {
      phases = [ "preConfigure" ] ++ (args.phases or []);
      preConfigure = ''
        export CFLAGS="$CFLAGS ${flags} ${cflags}"
        export FFLAGS="$FFLAGS ${flags} ${fflags}"
        export FCFLAGS="$FCFLAGS ${flags} ${fflags}"
        export LDFLAGS="$LDFLAGS ${flags} ${ldflags}"
      '' + "${args.preConfigure or ""}";
    });
  };

  # newStdenv = stdenv: stdenv // (mkDerivation = args: stdenv.mkDerivation (args // {}));
  optimizePackage = pkg: customFlags { cflags="${extraNativeCflags pkg.stdenv}";} pkg;
  withOpenMP = customFlags      { flags="-fopenmp"; };

  optimizedStdEnv = stdenv: customFlagsWithinStdEnv { cflags="${extraNativeCflags stdenv}";} stdenv;
}
