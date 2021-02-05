{ stdenv, lib, fetchannex, gcc, file
, cpio, rpm
, patchelf
, version ? "2019.0.117"
, url
, sha256
, preinstDir ? "opt/intel/compilers_and_libraries_${version}/linux"
}:

let
  components_ = [
    "intel-comp*"
    "intel-openmp*"
    "intel-icc*"
    "intel-ifort*"
  ] ++ lib.optionals (lib.versionOlder "2017.99.999" version) [ "intel-c-comp*" ];

  extract = pattern: ''
    for rpm in $(ls $build/rpm/${pattern}.rpm | grep -v 32bit); do
      echo "Extracting: $rpm"
      ${rpm}/bin/rpm2cpio $rpm | ${cpio}/bin/cpio -ivd
    done
  '';

self = stdenv.mkDerivation rec {
  inherit version;
  name = "intel-compilers-${version}";

  src = fetchannex { inherit url sha256; };

  nativeBuildInputs= [ file patchelf ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    set -xv
    export build=$PWD
    mkdir $out
    cd $out
    echo "${lib.concatStringsSep "+" components_}"
    ${lib.concatMapStringsSep "\n" extract components_}

    mv ${preinstDir}/* .
    rm -rf opt
    set +xv
  '';

  preFixup = ''
    # Fixing man path
    rm -f $out/documentation
    rm -f $out/man

    #TODO keep $ORIGIN:$ORIGIN/../lib
    #autopatchelf "$out"

    echo "Patching rpath and interpreter..."
    for f in $(find $out -type f -executable); do
      type="$(file -b --mime-type $f)"
      case "$type" in
      "application/executable"|"application/x-executable")
        echo "Patching executable: $f"
        patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib $f || true
        ;;
      "application/x-sharedlib"|"application/x-pie-executable")
        echo "Patching library: $f"
        patchelf --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib $f || true
        ;;
      *)
        echo "$f ($type) not patched"
        ;;
      esac
    done

    echo "Fixing path into scripts..."
    for file in `grep -l -r "/${preinstDir}/" $out`
    do
      sed -e "s,/${preinstDir}/,$out,g" -i $file
    done

    libc=$(dirname $(dirname $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2)))
    for comp in icc icpc ifort ; do
      echo "-idirafter $libc/include -dynamic-linker $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2)" >> $out/bin/intel64/$comp.cfg
    done

    for comp in icc icpc ifort xild xiar; do
      echo "#!/bin/sh" > $out/bin/$comp

      echo "export PATH=${gcc}/bin:${gcc.cc}/bin:\$PATH" >> $out/bin/$comp
      echo "source $out/bin/compilervars.sh intel64" >> $out/bin/$comp
      echo "$out/bin/intel64/$comp \"\$@\"" >> $out/bin/$comp
      chmod +x $out/bin/$comp
    done

    ln -s $out/compiler/lib/intel64_lin $out/lib
  '';

  enableParallelBuilding = true;

  passthru = {
    lib = self; # compatibility with gcc, so that `stdenv.cc.cc.lib` works on both
    isIntel = true;
    hardeningUnsupportedFlags = [ "stackprotector" ];
    langFortran = true;
  } // lib.optionalAttrs stdenv.isLinux {
    inherit gcc;
  };

  meta = {
    description = "Intel compilers and libraries ${version}";
    maintainers = [ lib.maintainers.guibert ];
    platforms = lib.platforms.linux;
  };
};
in self
