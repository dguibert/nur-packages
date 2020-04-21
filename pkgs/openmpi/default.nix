{ stdenv, fetchurl, fetchpatch, gfortran, perl, libnl
, rdma-core, zlib, numactl, libevent, hwloc, pkgsTargetTarget
, ucx

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

  openmpi_2_0_2 = lib.upgradeOverride (openmpi) (oldAttrs: rec {
    version = "2.0.2";
    src = with stdenv.lib.versions; fetchurl {
      url = "https://www.open-mpi.org/software/ompi/v${major version}.${minor version}/downloads/${oldAttrs.pname}-${version}.tar.gz";
      #url = "https://download.open-mpi.org/release/open-mpi/v2.0/openmpi-2.0.2.tar.gz";
      sha256 = "sha256-MpFMxkeA05gAZvO+OSCwKM04HJTRJipVQV/B0AK64KU=";
    };
    buildInputs = oldAttrs.buildInputs
      ++ lib.optionals enableSlurm [ slurm /*pmix*/ ]
    ;
    configureFlags = oldAttrs.configureFlags
      ++ lib.optionals enableSlurm [
        "--with-slurm"
        "--with-pmix=internal"
        #"--with-hwloc"
        #"--with-libevent"
        ]
    ;
  });

  #openmpi_4_0_2 = lib.upgradeOverride (openmpi.override args_) (oldAttrs: rec {
  openmpi_4_0_2 = lib.upgradeOverride (openmpi) (oldAttrs: rec {
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
      ++ lib.optional enableSlurm "--with-slurm --with-pmi=${pmix}"
      ++ lib.optional (ucx != null) "--enable-mca-no-build=btl-uct"
    ;

  });

  self = {
    inherit openmpi_2_0_2;
    inherit openmpi_4_0_2;
    openmpi = self.openmpi_4_0_2;
  };
in self
