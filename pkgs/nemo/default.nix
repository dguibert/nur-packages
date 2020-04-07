{ stdenv, fetchsvn
, gfortran
, openmpi
, mpi ? openmpi
, netcdf
, netcdffortran
, hdf5
, perl
, perlPackages
, substituteAll
, xios_10 # for nemo_36
, xios
, fetchpatch, lib
}:

let
  nemo_arch-X64_nix-fcm = substituteAll {
    src = ./arch-X64_nix.fcm;
    inherit netcdffortran xios;
    fc=if ((mpi.isIntel or false) && (stdenv.cc.isIntel or false)) then "mpiifort" else "mpif90";
    cc=if ((mpi.isIntel or false) && (stdenv.cc.isIntel or false)) then "mpiicc" else "mpicc";
    fflags=if (stdenv.cc.isIntel or false) then
      "-g -i4 -r8 -O3 -fp-model precise -fno-alias -traceback" else
      "-g -fdefault-real-8 -O3 -funroll-all-loops -fcray-pointer -ffree-line-length-none";
  };

  generic = config: attrs: (stdenv.mkDerivation {
    pname = "nemo_${config}";
    buildInputs = [ gfortran mpi netcdf netcdffortran hdf5 perl
      perlPackages.URI
    ];
    postPatch = ''
      patchShebangs .
    '';
    buildPhase = ''
      cp ${nemo_arch-X64_nix-fcm} arch/arch-X64_nix.fcm
      cat arch/arch-X64_nix.fcm
      if test -e tests/${config}; then
        ./makenemo -a ${config} -m X64_nix -j$(nproc)
      elif test -e cfgs/${config}; then
        ./makenemo -r ${config} -m X64_nix -j$(nproc)
      else
        echo "ERROR: neither 'tests/${config}' nor 'cfgs/${config}' can be found"
        exit 10
      fi
    '';
    installPhase = ''
      if test -e tests/${config}; then
        mkdir -p $out/share/nemo/tests/${config}/
        cp -av tests/${config}/EXP00 $out/share/nemo/tests/${config}
        rm $out/share/nemo/tests/${config}/EXP00/nemo
        cp -aLv tests/${config}/EXP00/nemo $out/share/nemo/tests/${config}/EXP00/

        # create symlink just to call nemo directly
        mkdir $out/bin
        ln -s $out/share/nemo/tests/${config}/EXP00/nemo $out/bin/nemo

      elif test -e cfgs/${config}; then

        mkdir -p $out/share/nemo/cfgs/${config}/
        cp -av cfgs/${config}/EXP00 $out/share/nemo/cfgs/${config}
        rm $out/share/nemo/cfgs/${config}/EXP00/nemo
        cp -aLv cfgs/${config}/EXP00/nemo $out/share/nemo/cfgs/${config}/EXP00/

        # create symlink just to call nemo directly
        mkdir $out/bin
        ln -s $out/share/nemo/cfgs/${config}/EXP00/nemo $out/bin/nemo

      fi
    '';
  }).overrideAttrs attrs;


  nemo_gyre_36 = generic "GYRE" (o: {
    name = "nemo_3.6-10379";
    src = fetchsvn {
      url = "http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-3.6/NEMOGCM";
      rev = "10379";
      sha256 = "1pgaah508j9lya6mqasmxzs2j722ri4501346rvjcimkq560kc87";
    };
    buildInputs = o.buildInputs ++ [ xios_10 ];
    installPhase = ''
      mkdir -p $out/share/nemo/CONFIG/GYRE
      cp -av CONFIG/GYRE/EXP00 $out/share/nemo/CONFIG/GYRE
      rm $out/share/nemo/CONFIG/GYRE/EXP00/opa
      cp -aLv CONFIG/GYRE/BLD/bin/nemo.exe $out/share/nemo/CONFIG/GYRE/EXP00/opa
      cp -a CONFIG/SHARED $out/share/nemo/CONFIG

      # create symlink just to call nemo directly
      mkdir $out/bin
      ln -s $out/share/nemo/CONFIG/GYRE/EXP00/opa $out/bin/nemo
    '';
  });


  versions = {
    "4.0-10741" = (o: { version = "4.0-10741";
      src = fetchsvn {
        url = "http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0";
        rev = "10741";
        sha256 = "1w8hv1alqvyl5lgjd9xw3kfbvj15sp0aaf9ky0s151kcvkdjm40j";
      };
      buildInputs = o.buildInputs ++ [ xios ];
    });
    "4.0.2-12578" = (o: { version = "4.0.2-12578";
      src = fetchsvn {
        url = "http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.2";
        rev = "12578";
        sha256 = "sha256-nDehVdEs0ndd5Ti/GAQuLbLza5V8N7Y6DxZMslMZ5wg=";
      };
      buildInputs = o.buildInputs ++ [ xios ];
    });
    "4.0.2-12660-GO8_package" = (o: { version = "4.0.2-12660-GO8_package";
      src = fetchsvn {
        url = "http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/UKMO/NEMO_4.0.2_GO8_package";
        rev = "12660";
        sha256 = "sha256-AiYaw4Wuds5ZMCih1mb0yZY8ccFJ1Ok8N1icsaXjrjI=";
      };
      buildInputs = o.buildInputs ++ [ xios ];
    });
  };

  self = {
    inherit
      nemo_arch-X64_nix-fcm
      nemo_gyre_36
    ;
    nemo_bench_4_0       = generic "BENCH"       versions."4.0-10741";
    nemo_gyre_pisces_4_0 = generic "GYRE_PISCES" versions."4.0-10741";

    nemo_bench_4_0_2       = generic "BENCH"       versions."4.0.2-12578";
    nemo_gyre_pisces_4_0_2 = generic "GYRE_PISCES" versions."4.0.2-12578";

    nemo_meto_go8_4_0_2 = (generic "METO_GO" versions."4.0.2-12660-GO8_package").overrideAttrs (o: {
      patches = [
        (fetchpatch {
          name = "nemo-4.0.1_GO8_package-fix-duplicate.patch";
          url="https://forge.ipsl.jussieu.fr/nemo/changeset/12540/NEMO/branches/UKMO/NEMO_4.0.1_GO8_package_Intelfix?format=diff&new=12540";
          sha256 = "sha256-dDLIcUaEdNdiOcHQ3BztWeLTlgih0AI4UN7pzbcmsF8=";
          stripLen = 3;
        })
      ];
      postPatch = o.postPatch + ''
        echo "bld::tool::fppkeys   key_mpp_mpi key_si3 key_nosignedzero key_iomput" > cfgs/METO_GO/cpp_METO_GO.fcm
        echo "METO_GO OCE ICE" >> cfgs/ref_cfgs.txt
'';
    });

    nemo = self.nemo_bench_4_0;
  };
in self
