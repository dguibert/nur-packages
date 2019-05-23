{ stdenv, requireFile
, nix-patchtools
, zlib
, ncurses
, more
, rpm
, libxml2
, version
, sha256
}:

stdenv.mkDerivation rec {
  name = "arm-compiler-for-hpc-${version}";
  src = requireFile {
    url = "https://developer.arm.com/products/software-development-tools/compilers";
    name = "ARM-Compiler-for-HPC.19.0_RHEL_7_aarch64.tar";
    inherit sha256;
  };
  dontStrip = true;

  buildInputs = [ nix-patchtools more rpm];
  libs = stdenv.lib.makeLibraryPath [
    stdenv.cc.cc.lib /* libstdc++.so.6 */
    #llvmPackages_7.llvm # libLLVM.7.so
    stdenv.cc.cc # libm
    stdenv.glibc
    zlib
    ncurses
    libxml2
    #"${placeholder "out"}/lib"
  ];
  installPhase = ''
    sed -i -e "s@/bin/ls@ls@" ${name}*.sh
    bash -x ./${name}*.sh --accept --install-to $out

    export libs=$libs:$out/lib
    autopatchelf $out
  '';
  passthru = {
    isClang = true;
    langFortran = true;
  };
}
