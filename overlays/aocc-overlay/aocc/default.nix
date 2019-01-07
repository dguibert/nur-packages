{ stdenv, requireFile
, nix-patchtools
, zlib
, ncurses
, libxml2
}:

stdenv.mkDerivation {
  name = "aocc-1.3.0";
  src = requireFile {
    url = "https://developer.amd.com/amd-aocc/";
    name = "AOCC-1.3.0-Compiler.tar.xz";
    sha256 = "0zi1j23h9gmw62d883m3yfa9hjkpznky5jlc4w2d34mmj4njwmms";
  };
  dontStrip = true;

  buildInputs = [ nix-patchtools ];
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
    mkdir $out
    cp -rv * $out
    rm -rf $out/lib32
    find $out -name "*-i386.so" -delete

    # Hack around lack of libtinfo in NixOS
    ln -s ${ncurses.out}/lib/libncursesw.so.6 $out/lib/libtinfo.so.5

    export libs=$libs:$out/lib
    autopatchelf $out
  '';
  passthru = {
    isClang = true;
    langFortran = true;
  };
}
