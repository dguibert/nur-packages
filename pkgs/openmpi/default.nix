{ stdenv, fetchurl, fetchpatch, gfortran, perl, libnl
, rdma-core, zlib, numactl, libevent, hwloc
, openucx ? null
, libfabric ? null

# Enable the Sun Grid Engine bindings
, enableSGE ? false

# Enable Slurm/PMI binding
, enableSlurm ? false
, slurm

# Pass PATH/LD_LIBRARY_PATH to point to current mpirun by default
, enablePrefix ? false
}:

let
  version = "4.0.1";

in stdenv.mkDerivation rec {
  name = "openmpi-${version}";

  src = with stdenv.lib.versions; fetchurl {
    url = "https://www.open-mpi.org/software/ompi/v${major version}.${minor version}/downloads/${name}.tar.bz2";
    sha256 = "02cpzcp113gj5hb0j2xc0cqma2fn04i2i0bzf80r71120p9bdryc";
  };

  patches = [
    (fetchpatch {
      name = "openmpi-mca_btl_vader_component_close-segfault.patch";
      url = "https://github.com/open-mpi/ompi/pull/6526.patch";
      sha256 = "0s7ac9rkcj3fi6ampkvy76njlj478yyr4zvypjc7licy6dgr595x";
    })
  ];

  postPatch = ''
    patchShebangs ./
  '';

  buildInputs = with stdenv; [ gfortran zlib openucx libfabric ]
    ++ lib.optionals isLinux [ libnl numactl ]
    ++ lib.optionals enableSlurm [ slurm ]
    ++ [ libevent hwloc ]
    ++ lib.optional (isLinux || isFreeBSD) rdma-core;

  nativeBuildInputs = [ perl ];

  configureFlags = with stdenv; [ "--disable-mca-dso" ]
    ++ lib.optional isLinux  "--with-libnl=${libnl.dev}"
    ++ lib.optional enableSGE "--with-sge"
    ++ lib.optional enableSlurm "--with-pmi=${slurm.dev} --with-pmi-libdir=${slurm}/lib"
    ++ lib.optional enablePrefix "--enable-mpirun-prefix-by-default"
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
