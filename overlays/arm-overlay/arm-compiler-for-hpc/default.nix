{ stdenv, fetchannex
, nix-patchtools
, zlib
, ncurses
, more
, cpio, rpm
, libxml2
, version
, sha256
, lib
}:

let
  components_ = [
    #"arm-compiler-for-hpc-19.0_Generic-AArch64_RHEL-7_aarch64-linux-19.0-45.aarch64.rpm"
    #armpl-19.0.0_Cortex-A72_RHEL-7_arm-hpc-compiler_19.0_aarch64-linux-19.0.0-22.aarch64.rpm
    #armpl-19.0.0_Cortex-A72_RHEL-7_gcc_8.2.0_aarch64-linux-19.0.0-22.aarch64.rpm
    #armpl-19.0.0_Generic-AArch64_RHEL-7_gcc_8.2.0_aarch64-linux-19.0.0-22.aarch64.rpm
    #armpl-19.0.0_ThunderX2CN99_RHEL-7_arm-hpc-compiler_19.0_aarch64-linux-19.0.0-22.aarch64.rpm
    #armpl-19.0.0_ThunderX2CN99_RHEL-7_gcc_8.2.0_aarch64-linux-19.0.0-22.aarch64.rpm
    #gcc-8.2.0_Generic-AArch64_RHEL-7_aarch64-linux-8.2.0-2.aarch64.rpm
  ];

  extract = pattern: ''
    for rpm in $(ls $build/rpms/${pattern}); do
      echo "Extracting: $rpm"
      ${rpm}/bin/rpm2cpio $rpm | ${cpio}/bin/cpio -ivd
    done
  '';

  ext = if lib.versionOlder version "2.0"
    then "hpc"
    else "linux";
  Ext = if lib.versionOlder version "2.0"
    then "HPC."
    else "Linux_";

  common = { components, extraLibs ? [], ... }@args: stdenv.mkDerivation (rec {
    name = "arm-compiler-for-${ext}-${version}";
    src = fetchannex {
      url = "https://developer.arm.com/products/software-development-tools/compilers";
      file = "Arm-Compiler-for-${Ext}${version}_RHEL_7_aarch64.tar";
      name = "Arm-Compiler-for-${Ext}${version}_RHEL_7_aarch64.tar";
      inherit sha256;
    };
    dontPatchELF = true;
    dontStrip = true;

    buildInputs = [ nix-patchtools more cpio rpm ];
    libs = stdenv.lib.makeLibraryPath ([
      stdenv.cc.cc.lib /* libstdc++.so.6 */
      #llvmPackages_7.llvm # libLLVM.7.so
      stdenv.cc.cc # libm
      stdenv.glibc
      zlib
      ncurses
      libxml2
      #"${placeholder "out"}/lib"
    ] ++ extraLibs);
    installPhase = ''
      sed -i -e "s@/bin/ls@ls@" ${name}*.sh
      bash -x ./${name}*.sh --accept --save-packages-to rpms

      set -xve
      export build=$PWD

      ls rpms

      mkdir $out; cd $out
      ${stdenv.lib.concatMapStringsSep "\n" extract components}

      set +xve

      mv opt/arm/*/* .
      rm -rf opt/*

      export libs=$libs:$out/lib
      autopatchelf $out
    '';
    passthru = {
      isClang = true;
      langFortran = true;
    };
  } // args);

in rec {
  unwrapped = common {
    components = [
      "arm-${ext}-compiler-${version}_Generic-AArch64_RHEL-7_aarch64-linux-*"
    ];
  };
  armpl = common {
    name = "armpl-${version}";
    components = [
      "armpl-${version}.0_Generic-AArch64_RHEL-7_arm-${ext}-compiler_${version}_aarch64-linux-*"
    ];
    extraLibs = [ unwrapped ];
    postFixup = ''
      rm -r $out/Generic-AArch64
    '';
  };
}
