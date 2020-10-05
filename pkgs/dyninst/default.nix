{ stdenv, fetchFromGitHub
, cmake
, boost
, libelf
, elfutils
, libdwarf
, libiberty
, tbb
}:

stdenv.mkDerivation {
  name = "dyninst-10.1.0";
  src = fetchFromGitHub {
    owner = "dyninst";
    repo = "dyninst";
    rev = "refs/tags/v10.1.0";
    sha256 = "sha256-7WO1RwlSfFVoUfLIJL25Y7dMvpx5Z5jl5G9fnoobRgg=";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ boost elfutils libelf libdwarf libiberty tbb ];
  propagatedBuildInputs = [ boost tbb /* tbb/concurrent_hash_map.h: No such file or directory */ ];
  postPatch = "patchShebangs .";
  cmakeFlags = [
    "-DBUILD_RTLIB_32=ON"
  ];
}

