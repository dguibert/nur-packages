{ stdenv, fetchurl
, blas ? openblas, openblas
, mpi ? openmpi, openmpi

, fetchannex
, nvidia_x11 ? linuxPackages.nvidia_x11, linuxPackages
, cudatoolkit_10_1
, openmpi_3_1 ? openmpi
, mkl
, nix-patchtools
, glibc
, gcc48
, callPackage
}:

let

  hpl_netlib_2_3 = stdenv.mkDerivation {
    name = "hpl-2.3";
    src = fetchurl {
      url = "http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz";
      sha256 = "0c18c7fzlqxifz1bf3izil0bczv3a7nsv0dn6winy3ik49yw3i9j";
    };
    buildInputs = [ blas mpi ];
    #-DHPL_COPY_L  force the copy of the panel L before bcast
    #-DHPL_CALL_CBLAS  call the BLAS C interface
    #-DHPL_CALL_VSIPL  call the vsip library
    #-DHPL_DETAILED_TIMING   enable detailed timers
    ## + https://www.netlib.org/benchmark/hpl/tuning.html
    #makeFlags = [
    #  "HPL_OPTS="
    #];
    meta = {
      description = "A Portable Implementation of the High-Performance Linpack";
    };
  };

  hpl_mkl_netlib_2_3 = callPackage ({stdenv, fetchurl, mkl, mpi}: stdenv.mkDerivation {
    name = "hpl-2.3";
    src = fetchurl {
      url = "http://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz";
      sha256 = "0c18c7fzlqxifz1bf3izil0bczv3a7nsv0dn6winy3ik49yw3i9j";
    };
    buildInputs = [ mkl mpi ];
    #-DHPL_COPY_L  force the copy of the panel L before bcast
    #-DHPL_CALL_CBLAS  call the BLAS C interface
    #-DHPL_CALL_VSIPL  call the vsip library
    #-DHPL_DETAILED_TIMING   enable detailed timers
    ## + https://www.netlib.org/benchmark/hpl/tuning.html
    #makeFlags = [
    #  "HPL_OPTS=-DHPL_CALL_CBLAS"
    #];
    LDFLAGS="-lm";
    meta = {
      description = "A Portable Implementation of the High-Performance Linpack";
    };
  }) { inherit mpi; };

  hpl_cuda_ompi_volta_pascal_kepler_3_14_19 = stdenv.mkDerivation {
    name = "hpl_cuda_10.1_ompi-3.1_volta_pascal_kepler-3.14.19";
    src = fetchannex {
      url = "hpl_cuda_10.1_ompi-3.1_volta_pascal_kepler_3-14-19_ext.tgz";
      sha256 = "0xynj4yd4n7nc22pxmzxbpl64m5rlv38lwbs3j50wc94j6sjfy1x";
    };
    buildInputs = [ nix-patchtools ];
    libs = stdenv.lib.makeLibraryPath [
      cudatoolkit_10_1.lib
      cudatoolkit_10_1.out
      nvidia_x11
      openmpi
      mkl
      glibc
      gcc48.cc.lib
    ];
    dontStrip = true;
    installPhase = ''
      mkdir -p $out/bin
      cp xhpl* $out/bin/

      echo $libs
      autopatchelf $out
    '';
  };

in rec {
  inherit hpl_netlib_2_3;
  inherit hpl_mkl_netlib_2_3;
  inherit hpl_cuda_ompi_volta_pascal_kepler_3_14_19;
}
