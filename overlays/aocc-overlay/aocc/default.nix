{
  stdenv,
  requireFile,
  fetchurl,
  nix-patchtools,
  zlib,
  ncurses,
  libxml2,
  version,
  sha256,
  lib,
  libffi_3_2,
  libffi,
  elfutils,
  rocmPackages,
}: let
  require_file = requireFile {
    url = "https://developer.amd.com/amd-aocc/";
    name =
      if lib.versionOlder version "2.0"
      then "AOCC-${version}-Compiler.tar.xz"
      else "aocc-compiler-${version}.tar";
    inherit sha256;
  };
in
  stdenv.mkDerivation {
    name = "aocc-${version}";
    src = fetchurl {
      url =
        {
          "5.0.0" = "https://download.amd.com/developer/eula/aocc/aocc-5-0/aocc-compiler-5.0.0.tar";
          "4.2.0" = "https://download.amd.com/developer/eula/aocc/aocc-4-2/aocc-compiler-4.2.0.tar";
          "3.2.0" = "https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-3.2.0.tar";
        }
        .${version};
      inherit sha256;
    };
    dontStrip = true;
    dontPatchELF = true;

    buildInputs = [nix-patchtools];
    libs = lib.makeLibraryPath ([
        stdenv.cc.cc.lib
        /*
        libstdc++.so.6
        */
        #llvmPackages_7.llvm # libLLVM.7.so
        stdenv.cc.cc # libm
        stdenv.cc.libc
        zlib
        ncurses
        libxml2
        #"${placeholder "out"}/lib"
      ]
      ++ lib.optionals (lib.versionAtLeast version "2.0.0") [
        libffi_3_2 # libffi.so.6
        elfutils
      ]
      ++ lib.optionals (lib.versionAtLeast version "3.1.0") [
        rocmPackages.rocm-runtime
      ]
      ++ lib.optionals (lib.versionAtLeast version "5.0.0") [
        # libffi # libffi-3.4.6/lib libffi.so.8.1.4
      ]);
    installPhase = ''
      mkdir $out
      cp -rv * $out
      rm -rf $out/lib32
      find $out -name "*-i386.so" -delete

      # Hack around lack of libtinfo in NixOS
      ln -vs ${ncurses.out}/lib/libncursesw.so.6 $out/lib/libtinfo.so.5
      ln -vs ${zlib}/lib/libz.so.1 $out/lib/libz.so.1
      #ln -vs ${stdenv.cc.libc.bin}/lib/libdl.so* $out/lib/
      #ln -vs ${stdenv.cc.libc}/lib/libpthread.so.0 $out/lib/libpthread.so.0

      export libs=$libs:$out/lib
      echo "LIBS: $libs"
      autopatchelf $out
    '';
    passthru = {
      isClang = true;
      langFortran = true;
      hardeningUnsupportedFlags = ["zerocallusedregs"];
    };
  }
