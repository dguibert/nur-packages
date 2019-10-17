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
}:

let
  version = "4.0.2";

in stdenv.mkDerivation rec {
  pname = "openmpi";
  inherit version;

  src = with stdenv.lib.versions; fetchurl {
    url = "https://www.open-mpi.org/software/ompi/v${major version}.${minor version}/downloads/${pname}-${version}.tar.bz2";
    sha256 = "0ms0zvyxyy3pnx9qwib6zaljyp2b3ixny64xvq3czv3jpr8zf2wh";
  };

  postPatch = ''
    patchShebangs ./

    # Ensure build is reproducible
    ts=`date -d @$SOURCE_DATE_EPOCH`
    sed -i 's/OPAL_CONFIGURE_USER=.*/OPAL_CONFIGURE_USER="nixbld"/' configure
    sed -i 's/OPAL_CONFIGURE_HOST=.*/OPAL_CONFIGURE_HOST="localhost"/' configure
    sed -i "s/OPAL_CONFIGURE_DATE=.*/OPAL_CONFIGURE_DATE=\"$ts\"/" configure
    find -name "Makefile.in" -exec sed -i "s/\`date\`/$ts/" \{} \;
  '';

  buildInputs = with stdenv; [ gfortran zlib openucx libfabric ]
    ++ lib.optionals isLinux [ libnl numactl ]
    ++ lib.optionals enableSlurm [ slurm pmix ]
    ++ [ libevent hwloc ]
    ++ lib.optional (isLinux || isFreeBSD) rdma-core;

  nativeBuildInputs = [ perl ];

  configureFlags = with stdenv; [ "--disable-mca-dso" "--with-cma" ]
    ++ lib.optional isLinux  "--with-libnl=${libnl.dev}"
    ++ lib.optional enableSGE "--with-sge"
    #++ lib.optional enableSlurm "--with-pmi=${slurm.dev} --with-pmi-libdir=${slurm}"
    ++ lib.optional enableSlurm "--with-pmi=${pmix}"
    ++ lib.optional enablePrefix "--enable-mpirun-prefix-by-default"
    ++ lib.optional (openucx != null) "--enable-mca-no-build=btl-uct"
    ##++ [ "--enable-mpi1-compatibility" ] # to avoid porting libraries (https://www.open-mpi.org/faq/?category=mpi-removed)
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
  postConfigure = stdenv.lib.optionalString (stdenv.cc.isIntel or false) ''
    echo "PATCHING config.status"
    find -name config.status | xargs -n 1 --verbose sed -i -e "s@lib\"'@/lib'@"
  '';

  enableParallelBuilding = true;

  postInstall = ''
    rm -f $out/lib/*.la
   '';

  postFixup = ''
    # default compilers should be indentical to the
    # compilers at build time

    sed -i 's:compiler=.*:compiler=${pkgsTargetTarget.stdenv.cc}/bin/${pkgsTargetTarget.stdenv.cc.targetPrefix}cc:' \
      $out/share/openmpi/mpicc-wrapper-data.txt

    sed -i 's:compiler=.*:compiler=${pkgsTargetTarget.stdenv.cc}/bin/${pkgsTargetTarget.stdenv.cc.targetPrefix}cc:' \
       $out/share/openmpi/ortecc-wrapper-data.txt

    sed -i 's:compiler=.*:compiler=${pkgsTargetTarget.stdenv.cc}/bin/${pkgsTargetTarget.stdenv.cc.targetPrefix}c++:' \
       $out/share/openmpi/mpic++-wrapper-data.txt

    sed -i 's:compiler=.*:compiler=${pkgsTargetTarget.gfortran}/bin/${pkgsTargetTarget.gfortran.targetPrefix}gfortran:'  \
       $out/share/openmpi/mpifort-wrapper-data.txt
  '';

  doCheck = true;

  meta = with stdenv.lib; {
    homepage = https://www.open-mpi.org/;
    description = "Open source MPI-3 implementation";
    longDescription = "The Open MPI Project is an open source MPI-3 implementation that is developed and maintained by a consortium of academic, research, and industry partners. Open MPI is therefore able to combine the expertise, technologies, and resources from all across the High Performance Computing community in order to build the best MPI library available. Open MPI offers advantages for system and software vendors, application developers and computer science researchers.";
    maintainers = with maintainers; [ markuskowa dguibert ];
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
