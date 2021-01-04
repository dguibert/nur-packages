{ stdenv, fetchFromGitHub
, cmake
, boost
, otf2
, binutils
, git
, libbfd
, zlib
, libiberty
, pkgconfig
}:

stdenv.mkDerivation {
  name = "lo2s-1.2.2-22-g53c0b85";
  src = fetchFromGitHub {
    owner = "tud-zih-energy";
    repo = "lo2s";
    rev = "53c0b85166bf50208838380186e50350f6e79f14";
    sha256 = "sha256-pYwBkTd0Hr7cF9wsmSEn5tessg92b64JGeqdBqO0/3I=";
    fetchSubmodules = true;
    leaveDotGit = true;
  };
  preConfigure = ''
    sed -i -e "s/git_submodule_update()/#git_submodule_update()/" CMakeLists.txt
    sed -i -e "s/git_submodule_update()/#git_submodule_update()/" lib/nitro/CMakeLists.txt
  '';

  cmakeFlags = [
    "-Dlo2s_USE_STATIC_LIBS=OFF"
  ];

  buildInputs = [
    cmake
    #(boost.override { enableStatic=true; }).all
    boost
    otf2 git libbfd zlib libiberty pkgconfig
  ];
#  meta.broken = true;
}

