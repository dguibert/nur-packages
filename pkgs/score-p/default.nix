{
  stdenv,
  lib,
  fetchurl,
  otf2,
  openmpi,
  mpi ? openmpi,
  which,
  gfortran,
  zlib,
  pkg-config,
  cubew,
  cubelib,
  autoreconfHook,
}:
stdenv.mkDerivation {
  pname = "score-p";
  version = "7.1";
  src = fetchurl {
    url = "http://perftools.pages.jsc.fz-juelich.de/cicd/scorep/tags/scorep-7.1/scorep-7.1.tar.gz";
    sha256 = "sha256-mN6kl5ggAfuC2jQpylVmmykXoIWMcaviz+fNETOB8fc=";
  };
  buildInputs = [
    otf2
    mpi
    which
    gfortran
    zlib
    pkg-config
    cubew
    cubelib
    /*
    opari
    */
  ];
  nativeBuildInputs = [autoreconfHook];
  configureFlags = [
    "${lib.optionalString stdenv.cc.isIntel or false "--with-nocross-compiler-suite=intel"}"
    #--with-mpi=(bullxmpi|hp|ibmpoe|intel|intel2|intel3|intelpoe|lam|mpibull2|mpich|mpich2|mpich3|openmpi|platform|scali|sgimpt|sgimptwrapper|sun)
    "${lib.optionalString mpi.isIntel or false "--with-mpi=intel3"}"
  ];
  postConfigure = ''
    ${lib.optionalString stdenv.cc.isIntel or false ''
      # remove wrong lib path
      for f in $(find -name libtool); do
      echo "PATCHING $f"
        sed -i.bak -e 's@\(intel-compilers-.*/lib\)\\"@\1@' $f
      done
    ''}
  '';

  postInstall = ''
    # RPATH of binary /nix/store/8b7q0yzfb8chmgr4yqybfrlrvvnrlq1i-score-p-3.0/bin/scorep-score contains a forbidden reference to /tmp/nix-build-score-p-3.1.drv-0
    while IFS= read -r -d ''$'\0' i; do
      if ! isELF "$i"; then continue; fi
      echo "patching $i..."
      rpath=`patchelf --print-rpath $i | sed -e "s@$TMPDIR/.*:@\$out/lib:@"`;
      patchelf --set-rpath "$rpath" "$i"
    done < <(find $out/bin -type f -print0)
      ${lib.optionalString mpi.isIntel or false ''
      rm $out/bin/scorep-mpi*
      ln -s $out/bin/scorep-wrapper $out/bin/scorep-mpiicc
      ln -s $out/bin/scorep-wrapper $out/bin/scorep-mpiicpc
      ln -s $out/bin/scorep-wrapper $out/bin/scorep-mpiifort
    ''}
  '';
  enableParallelBuilding = true;
}
