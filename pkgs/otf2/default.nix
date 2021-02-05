{ stdenv, lib, fetchurl }:
stdenv.mkDerivation {
  name = "otf2-2.2";
  src = fetchurl {
    url = "https://www.vi-hps.org/cms/upload/packages/otf2/otf2-2.2.tar.gz";
    sha256 = "0b8p2wqy8zza86nbwq0yqh131qhygd2f2b6avn77gp1r73wrllfh";
  };
  configureFlags = [
    #"--with-frontend-compiler-suite=(gcc|ibm|intel|pgi|studio)"
    "${lib.optionalString stdenv.cc.isIntel or false "--with-nocross-compiler-suite=intel"}"
  ];
}

