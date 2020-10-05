{ stdenv
, fetchurl
, hdf5
, m4
, curl # for DAP
, compilers_line
}:

let
  mpiSupport = hdf5.mpiSupport;
  mpi = hdf5.mpi;
in stdenv.mkDerivation rec {
  pname = "netcdf-c";
  version="4.7.3";

  src = fetchurl {
    url = "https://www.unidata.ucar.edu/downloads/netcdf/ftp/${pname}-${version}.tar.gz";
    sha256 = "sha256-joyfTuFVMd68+DeIWUdEvWVTuEicBqQ0haFck7TgRIs=";
  };

  postPatch = ''
    patchShebangs .

    # this test requires the net
    for a in ncdap_test/Makefile.am ncdap_test/Makefile.in; do
      substituteInPlace $a --replace testurl.sh " "
    done
  '';

  nativeBuildInputs = [ m4 ];
  buildInputs = [ hdf5 curl mpi ];

  passthru = {
    mpiSupport = mpiSupport;
    inherit mpi;
  };

  configureFlags = [
      "--enable-netcdf-4"
      "--enable-dap"
      "--enable-shared"
  ]
  ++ [ (compilers_line stdenv mpi) ]
  ++ (stdenv.lib.optionals mpiSupport [ "--enable-parallel-tests" ]);

  #doCheck = false; # FAIL: tst_io

  meta = {
      platforms = stdenv.lib.platforms.unix;
      homepage = https://www.unidata.ucar.edu/software/netcdf/;
      license = {
        url = https://www.unidata.ucar.edu/software/netcdf/docs/copyright.html;
      };
  };
}
