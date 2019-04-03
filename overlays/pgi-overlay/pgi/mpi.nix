{ stdenv, requireFile
, nix-patchtools
, more
, zlib
, ncurses
, libxml2
, version
, sha256
, glibc
, file
, gcc
, rdma-core
, numactl
, pgi
}:

stdenv.mkDerivation {
  name = "openmpi-pgi-2.1.2";
  src = requireFile {
    url = "https://www.pgroup.com/support/release_archive.php";
    name = "pgilinux-2018-${version}-x86-64.tar.gz";
    inherit sha256;
  };
  dontPatchELF = true;
  dontStrip = true;

  buildInputs = [ nix-patchtools more file gcc ];
  propagatedBuildInputs = [ pgi ];

  libs = stdenv.lib.makeLibraryPath [
    stdenv.cc.cc.lib /* libstdc++.so.6 */
    #llvmPackages_7.llvm # libLLVM.7.so
    stdenv.cc.cc # libm
    stdenv.glibc
    zlib
    ncurses
    libxml2
    #"${placeholder "out"}/lib"
  ];

  installPhase = ''
    mkdir $out
    # MPI
    tar xf openmpi-2.1.2-2018-x86-64.tar.gz
    tar xv --one-top-level=$out --strip-components=4 -f linux86-64.openmpi-2.1.2.tar.gz || true
    # /nix/store/dlwn87hlmxd78xiabj35yy6b5pbadjba-pgilinux-1810-mpi/bin/.bin/mpiCC: error while loading shared libraries: libibverbs.so.1: failed to map segment from shared object
    rm $out/lib/librdmacm.so.1
    rm $out/lib/libibverbs.so.1

    #TODO keep $ORIGIN:$ORIGIN/../lib
    ## autopatchelf $out
    echo "Patching rpath and interpreter..."
    for f in $(find $out -type f -executable); do
      type="$(file -b --mime-type $f)"
      case "$type" in
      "application/executable"|"application/x-executable")
        echo "Patching executable: $f"
        patchelf --set-interpreter $(echo ${glibc}/lib/ld-linux*.so.2) --set-rpath $libs:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../../lib:$ORIGIN/../lib64:${rdma-core}/lib:${numactl}/lib:${pgi.cc}/lib $f || true
        ;;
      "application/x-sharedlib"|"application/x-pie-executable")
        echo "Patching library: $f"
        patchelf --set-rpath $libs:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../../lib:$ORIGIN/../lib64:${rdma-core}/lib:${numactl}/lib:${pgi.cc}/lib $f || true
        ;;
      *)
        echo "$f ($type) not patched"
        ;;
      esac
    done

    patchShebangs $out
  '';
}
