{ stdenv, lib, fetchurl }:
stdenv.mkDerivation {
  name = "otf2-2.3";
  src = fetchurl {
    url = "http://perftools.pages.jsc.fz-juelich.de/cicd/otf2/tags/otf2-2.3/otf2-2.3.tar.gz";
    sha256 = "sha256-NpV0KNN8QNNba0UgjwUPtc/iPFTodBiXeKJLDpIZx+M=";
  };
  configureFlags = [
    #"--with-frontend-compiler-suite=(gcc|ibm|intel|pgi|studio)"
    "${lib.optionalString stdenv.cc.isIntel or false "--with-nocross-compiler-suite=intel"}"
  ];
}

