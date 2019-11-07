{ stdenv, fetchurl, fetchpatch, gfortran, perl, libnl
, rdma-core, zlib, numactl, libevent, hwloc, pkgsTargetTarget
, openucx
, libfabric

# Enable the Sun Grid Engine bindings
, enableSGE ? false

# Enable Slurm/PMI binding
, enableSlurm ? false
, slurm
, pmix

# Pass PATH/LD_LIBRARY_PATH to point to current mpirun by default
, enablePrefix ? false

, lib
, openmpi
}@args:

let
  args_ = builtins.removeAttrs args [ "lib" "openmpi" "enableSlurm" "slurm" "pmix"];

  openmpi_4_0_2 = lib.upgradeOverride (openmpi.override args_) (oldAttrs: rec {
    version = "4.0.2";
    src = with stdenv.lib.versions; fetchurl {
      url = "https://www.open-mpi.org/software/ompi/v${major version}.${minor version}/downloads/${oldAttrs.pname}-${version}.tar.bz2";
      sha256 = "0ms0zvyxyy3pnx9qwib6zaljyp2b3ixny64xvq3czv3jpr8zf2wh";
    };
    buildInputs = oldAttrs.buildInputs
      ++ lib.optionals enableSlurm [ slurm pmix ]
    ;
    configureFlags = oldAttrs.configureFlags
      ++ [ "--with-cma" ]
      ++ lib.optional enableSlurm "--with-pmi=${pmix}"
      ++ lib.optional (openucx != null) "--enable-mca-no-build=btl-uct"
    ;
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
    + stdenv.lib.optionalString (stdenv.cc.isIntel or false) ''
      echo "PATCHING config.status"
      find -name config.status | xargs -n 1 --verbose sed -i -e "s@lib\"'@/lib'@"
    '';


  });

in rec {
  inherit openmpi_4_0_2;
  openmpi = openmpi_4_0_2;
}
