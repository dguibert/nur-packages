nixpkgs:
final: prev: let

  # getSubDirectories :: Path -> [ String ]
  getSubDirectories = dir: let
    dirContents = builtins.readDir dir;
    isDirectory = name: dirContents.${name} == "directory";
  in builtins.filter isDirectory (builtins.attrNames dirContents);
  # keysToAttrs :: ( String -> a ) -> [ String ] -> { *: a }
  keysToAttrs = lambda: strings:
    builtins.listToAttrs (map (k: {
      name = k;
      value = lambda k;
    }) strings);


  # envNames :: [ string ]
  envNames =  getSubDirectories ./.;
  privateEnvNames =  getSubDirectories ../envs-private;
  # hostNames :: [ string ]
  hostNames = getSubDirectories ../hosts;

  mkHostExtend = final: name:
    builtins.trace "mkHostExtend for ${name}"
    final.envExtend(import (../hosts + "/${name}/overlay.nix"));
  mkExtend = final: name:
    builtins.trace "mkExtend for ${name}"
    final.envExtend(import (./. + "/${name}"));

  loadPrivateEnv = final: name:
    let
      env_private = final.sopsDecrypt_ (../envs-private + "/${name}/default-sec.nix")  "data";
      loaded = env_private.success or true;
    in if loaded
       then (builtins.trace "loaded encrypted ${../envs-private + "/${name}/default-sec.nix"} (${toString loaded})" final.envExtend(env_private))
       else (builtins.trace "use dummy        ${../envs-private + "/${name}/default-sec.nix"} (${toString loaded})" final.envExtend(final: prev: {}));

  # Compiler Environments with curtom mk function
  mkExtendsAttrs = {
    "_gcc-6" = mkGccExtend;
    "_gcc-7" = mkGccExtend;
    "_gcc-8" = mkGccExtend;
    "_gcc-9" = mkGccExtend;

    "_intel-2017" = mkIntelExtend;
    "_intel-2017_7_259" = mkIntelExtend;
    "_intel-2018" = mkIntelExtend;
    "_intel-2019" = mkIntelExtend;
    "_intel-2020" = mkIntelExtend;
    "_intel-2020_1_217" = mkIntelExtend;
    "_intel-2020_2_254" = mkIntelExtend;
    "_intel-2020_4_304" = mkIntelExtend;

    "_oneapi-2021_1_0" = mkOneApiExtend;
    "_oneapi-2021_2_0" = mkOneApiExtend;

    "_llvm-7" = mkLlvmExtend;
    "_llvm-8" = mkLlvmExtend;
    "_llvm-9" = mkLlvmExtend;

    "_aocc-121" = mkAoccExtend;
    "_aocc-130" = mkAoccExtend;
    "_aocc-131" = mkAoccExtend;
    "_aocc-200" = mkAoccExtend;
    "_aocc-210" = mkAoccExtend;

    "_arm-192" = mkArmExtend;
    "_arm-193" = mkArmExtend;
    "_arm-200" = mkArmExtend;

    "_pgi-1904" = mkPgiExtend;
    "_pgi-1910" = mkPgiExtend;
  };

  callMkExtend = final: name: mkExtendsAttrs."${name}" final name;

  mkGccExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkGccExtend for ${name}" final.envExtend(final: prev: {
    "gcc_gfortran${version}" = prev.wrapCC (prev."gcc${version}".cc.override {
      name = "gcc";
      langFortran = true;
    });
    userCompilers = [ final."gcc_gfortran${version}" ];
    userEnv = prev.overrideCC prev.stdenv final."gcc_gfortran${version}";
    userFC = final."gcc_gfortran${version}";
  });

  mkIntelExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkIntelExtend for ${name}" final.envExtend(final: prev: with final; {
      userCompilers = [ prev."intelPackages_${version}".compilers ];
      userFC = prev."intelPackages_${version}".compilers;
      userEnv = prev."intelPackages_${version}".stdenv;
      userMPI = prev."intelPackages_${version}".mpi;

      glibc = prev.callPackage ../pkgs/glibc/2.25 { };
      glibc_memusage = prev.callPackage ../pkgs/glibc/2.25 {
        withGd = true;
      };

      # Being redundant to avoid cycles on boot. TODO: find a better way
      glibcCross = prev.callPackage ../pkgs/glibc/2.25 {
        stdenv = crossLibcStdenv;
      };

      # Only supported on Linux, using glibc
      glibcLocales = if prev.stdenv.hostPlatform.libc == "glibc" then prev.callPackage ../pkgs/glibc/2.25/locales.nix { } else null;

      glibcInfo = prev.callPackage ../pkgs/glibc/2.25/info.nix { };

      glibc_multi = prev.callPackage ../pkgs/glibc/2.25/multi.nix {
        glibc32 = prev.pkgsi686Linux.glibc;
      };

    });

  mkOneApiExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkOneApiExtend for ${name}" final.envExtend(final: prev: {
    userCompilers = prev."oneapiPackages_${version}".compilers;
    userEnv = prev."oneapiPackages_${version}".stdenv;
    userFC = final."oneapiPackages_${version}".compilers;
    userMPI = final."oneapiPackages_${version}".mpi;
  });

  mkLlvmExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkLlvmExtend for ${name}" final.envExtend(final: prev: {
    userCompilers = [ prev."flangPackages_${version}".clang prev."flangPackages_${version}".flang ];
    userEnv = prev."flangPackages_${version}".stdenv;
    userFC = final."flangPackages_${version}".flang;
    userMPI = prev.userMPI.override { stdenv = final.userEnv; gfortran  = final.userFC; };
  });

  mkAoccExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkAoccExtend for ${name}" final.envExtend(final: prev: {
    userCompilers = [ prev."aoccPackages_${version}".clang prev."aoccPackages_${version}".aocc ];
    userEnv = prev."aoccPackages_${version}".stdenv;
    userFC = final."aoccPackages_${version}".aocc;
    userMPI = prev.userMPI.override { stdenv = final.userEnv; gfortran  = final.userFC; };
  });

  mkArmExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkArmExtend for ${name}" final.envExtend(final: prev: {
    userCompilers = [ prev."armPackages_${version}".clang prev."armPackages_${version}".arm ];
    userEnv = prev."armPackages_${version}".stdenv;
    userFC = final."armPackages_${version}".arm;
    userMPI = prev.userMPI.override { stdenv = final.userEnv; gfortran  = final.userFC; };

    hdf5 = prev.customFlags { flags="-fPIC"; } prev.hdf5;
    netcdf = prev.customFlags { flags="-fPIC"; } prev.netcdf;
  });

  mkPgiExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkPgiExtend for ${name}" final.envExtend(final: prev: {
    userCompilers = [ prev."pgiPackages_${version}".pgi ];
    userEnv = prev."pgiPackages_${version}".stdenv;
    userFC = final."pgiPackages_${version}".pgi;
    userMPI = prev.userMPI.override { stdenv = final.userEnv; gfortran  = final.userFC; };

    hdf5 = prev.customFlags { flags="-fPIC"; } prev.hdf5;
    netcdf = prev.customFlags { flags="-fPIC"; } prev.netcdf;
  });

  mkNewExtend = final: name: let
    version=(builtins.parseDrvName name).version;
    in builtins.trace "mkNewExtend for ${name}" final.envExtend(final: prev: {
  });
in with final; {
  __nixpkgs = nixpkgs;

  envExtend = overlay: if overlay == {}
    then final
    else import final.__nixpkgs {
      inherit (prev) system config;
      overlays = (prev.overlays or []) ++ [ overlay ];
      #overlays = [ overlay ] ++ (prev.overlays or []);
  };

  __envNames = (builtins.attrNames mkExtendsAttrs) ++ envNames;
  __hostNames = hostNames;

  # default user env
  userCompilers = [ final.gcc final.gfortran ];
  userMPI = final.openmpi;
  userEnv = final.stdenv;

  userFC = final.gfortran;

  fftw = prev.fftw.override { stdenv = final.userEnv; };

  hdf5_1_8 = builtins.trace "hdf5_1_8 via userEnv" (prev.hdf5_1_8.override {
    stdenv = final.userEnv;
    gfortran = null;
    szip = null;
    mpi = null;
  });
  hdf5 = builtins.trace "hdf5 via userEnv" (prev.hdf5.override {
    stdenv = final.userEnv;
    gfortran = null;
    szip = null;
    mpi = null;
  });
  hdf5-mpi = builtins.trace "hdf5-mpi via userEnv" appendToName "mpi" (final.hdf5.override {
    stdenv = final.userEnv;
    szip = null;
    mpi = final.userMPI;
  });

  hdf5-cpp = appendToName "cpp" (final.hdf5.override {
    stdenv = final.userEnv;
    cpp = true;
  });

  hdf5-fortran = (appendToName "fortran" (final.hdf5.override {
    stdenv = final.userEnv;
    gfortran = final.userFC;
  })).overrideAttrs (attrs: {
    configureFlags = (attrs.configureFlags or [])
                 ++ prev.lib.optional (final.userEnv.cc.isClang or false) [
      "CC=clang CXX=clang++ F77=flang FC=flang LDFLAGS=-Wl,-rpath,${prev.zlib}/lib"
      # $ ldd H5make_libsettings
      ## linux-vdso.so.1 (0x00007ffd043ce000)
      ## libdl.so.2 => /nix/store/681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27/lib/libdl.so.2 (0x00007f659220d000)
      ## libm.so.6 => /nix/store/681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27/lib/libm.so.6 (0x00007f6592077000)
      ## libz.so.1 => /nix/store/iiymx8j7nlar3gc23lfkcscvr61fng8s-zlib-1.2.11/lib/libz.so.1 (0x00007f6592058000)
      ## libc.so.6 => /nix/store/681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27/lib/libc.so.6 (0x00007f6591ea2000)
      ## /nix/store/681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27/lib/ld-linux-x86-64.so.2 => /nix/store/681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27/lib64/ld-linux-x86-64.so.2 (0x00007f6592214000)
    ];

  });
  hpl_netlib_2_3 = prev.hpl_netlib_2_3.override { stdenv = final.userEnv; mpi=final.userMPI;};
  hpl_mkl_netlib_2_3 = prev.hpl_mkl_netlib_2_3.override { stdenv = final.userEnv; mpi=final.userMPI;};

  ncview = builtins.trace "ncview via userEnv" prev.ncview.override { stdenv = final.userEnv; };
  netcdf = builtins.trace "netcdf via userEnv" prev.netcdf.override { stdenv = final.userEnv; };
  netcdf-mpi = builtins.trace "netcdf-mpi via userEnv" appendToName "mpi" (final.netcdf.override {
    stdenv = final.userEnv;
    hdf5 = final.hdf5-mpi;
  });

  netcdffortran = builtins.trace "netcdffortran via userEnv" ((prev.netcdffortran.override {
    stdenv = final.userEnv;
    gfortran = final.userFC;
    netcdf = final.netcdf;
    hdf5 = final.hdf5;
  }).overrideAttrs (attrs: rec {
    pname = "netcdf-fortran";
    version = "4.5.2";
    src = fetchurl {
      url = "https://www.unidata.ucar.edu/downloads/netcdf/ftp/${pname}-${version}.tar.gz";
      sha256 = "sha256-uVmTfX2QRRhOnSBAqRXZSn9NAYX0qdzrjwjJSwwzBKo=";
    };
    buildInputs = attrs.buildInputs ++ [ userMPI ];
    configureFlags = (attrs.configureFlags or "")
      + (compilers_line userEnv userMPI);
    ## fix fixed-form
    #preBuild = ''
    #  sed -i -e "14s: include:  include:" nf_test/ftst_rengrps.F
    #'';
    doCheck = false; # FAIL: f90tst_io
  }));

  openmpi = builtins.trace "openmpi via userEnv" (prev.openmpi.override { stdenv = final.userEnv; gfortran  = final.userFC; }).overrideAttrs (oldAttrs: {
    # Hack like in
    # https://oasis3mct.cerfacs.fr/svn/trunk/oasis3-mct/lib/mct/configure
    # # With Intel ifc, ignore the quoted -mGLOB_options_string stuff (quoted
    # # $LIBS confuse us, and the libraries appear later in the output anyway).
    # *mGLOB_options_string*)
    #   ac_fc_v_output=`echo $ac_fc_v_output | sed 's/"-mGLOB[^"]*"/ /g'` ;;
    #
    # but autoconf has a fix in lib/autoconf/fortran.m4 since 2003-10-08
    # http://www.susaaland.dk/sharedoc/autoconf-2.59/ChangeLog
    postConfigure = (oldAttrs.postConfigure or "")
      + final.lib.optionalString (final.userEnv.cc.isIntel or false) ''
        echo "debug: |${toString (final.userEnv.cc.isIntel or false)}|"
        echo "PATCHING config.status"
        find -name config.status | xargs -n 1 --verbose sed -i -e "s@lib\"'@/lib'@"
    '';
  });

  stream = prev.stream.override {
     stdenv = final.userEnv;
     gfortran = final.userFC;
  };

  xios = prev.xios.override { stdenv = final.userEnv;    mpi = final.userMPI; };
  nemo_bench_4_0 = builtins.trace "nemo_bench_4_0 via userEnv" prev.nemo_bench_4_0.override { stdenv = final.userEnv;    gfortran = final.userFC; mpi = final.userMPI; };

  test-dgemm = builtins.trace "test-dgemm via userEnv" prev.test-dgemm.override { stdenv = final.userEnv; };

  # helpers env function
  inherit
    mkExtends
    mkGccExtends
    mkIntelExtends
    mkLlvmExtends
    mkAoccExtends
    mkArmExtends
  ;

  # custom stackable environmments
  titan = final.envExtend (final: prev: {});
  # compiler flags
  _avx = final.envExtend((self: super: {
    userEnv = super.customFlagsWithinStdEnv {
      flags="-O3 -xAVX -qopt-zmm-usage=high -mcmodel=large -qopt-streaming-stores=always";
    } super.userEnv;
  }));
  _avx2 = final.envExtend((self: super: {
    userEnv = super.customFlagsWithinStdEnv {
      flags="-O3 -xCORE-AVX2 -qopt-zmm-usage=high -mcmodel=large -qopt-streaming-stores=always";
    } super.userEnv;
  }));
  _avx512 = final.envExtend((self: super: {
    userEnv = super.customFlagsWithinStdEnv {
      flags="-O3 -xCORE-AVX512 -qopt-zmm-usage=high -mcmodel=large -qopt-streaming-stores=always";
    } super.userEnv;
  }));

}
// (keysToAttrs (mkHostExtend   final) hostNames)
// (keysToAttrs (mkExtend       final) envNames)
// (keysToAttrs (callMkExtend   final) (builtins.attrNames mkExtendsAttrs))
// (keysToAttrs (loadPrivateEnv final) privateEnvNames)

