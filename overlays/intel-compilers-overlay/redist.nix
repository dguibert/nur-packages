{ stdenv, lib, fetchannex, glibc, file
, patchelf
, version ? "2019.0.117"
, url
, sha256
, preinstDir ? "compilers_and_libraries_${version}/linux"
, gcc
, nix-patchtools
, libpsm2
, rdma-core
}:

stdenv.mkDerivation rec {
  inherit version;
  name = "intel-compilers-redist-${version}";

  src = fetchannex { inherit url sha256; };
  nativeBuildInputs= [ file nix-patchtools ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    set -xv
    mkdir $out
    mv compilers_and_libraries_${version}/linux/* $out
    ln -s $out/compiler/lib/intel64_lin $out/lib
    set +xv
  '';

  libs = (lib.concatStringsSep ":" [
    "${placeholder "out"}/lib"
    "${placeholder "out"}/mpi/intel64/lib"
    "${placeholder "out"}/mpi/intel64/libfabric/lib"
  ]) + ":" + (lib.makeLibraryPath [
    stdenv.cc.libc
    gcc.cc.lib
    libpsm2
    rdma-core
  ]);

  preFixup = ''
    find $out -type d -name ia32_lin -print0 | xargs -0 -i rm -r {}
    autopatchelf "$out"

    echo "Fixing path into scripts..."
    for file in `grep -l -r "${preinstDir}/" $out`
    do
      sed -e "s,${preinstDir}/,$out,g" -i $file
    done
  '';

  meta = {
    description = "Intel compilers and libraries ${version}";
    maintainers = [ lib.maintainers.dguibert ];
    platforms = lib.platforms.linux;
  };

}
