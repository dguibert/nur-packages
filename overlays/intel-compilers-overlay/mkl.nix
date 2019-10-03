{ stdenv, fetchannex, gcc, file
, cpio, rpm
, patchelf
, version ? "2019.0.117"
, url
, sha256
, preinstDir ? "opt/intel/compilers_and_libraries_${version}/linux"
, config
, redist
, mpi
}:

let
  inherit (builtins) elem;
  licenseHelpMsg = text: ''
    error: ${text} for Intel Parallel Studio
     Packages that are part of Intel Parallel Studio require a license and acceptance
    of the End User License Agreement (EULA).
     You can purchase a license at
    https://software.intel.com/en-us/parallel-studio-xe
     You can review the EULA at
    https://software.intel.com/en-us/articles/end-user-license-agreement
     Once purchased, you can use your license with the Intel Parallel Studio Nix
    packages using the following methods:
     a) for `nixos-rebuild` you can indicate the license file to use and your
       acceptance of the EULA by adding lines to `nixpkgs.config` in the
       configuration.nix, like so:
         {
           nixpkgs.config.psxe.licenseFile = /home/user/COM_L___XXXX-XXXXXXXX.lic;
         }
     b) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you can
       indicate the license file to use and your acceptance of the EULA by adding
       lines to ~/.config/nixpkgs/config.nix, like so:
          {
            psxe.licenseFile = /home/user/COM_L___XXXX-XXXXXXXX.lic;
          }
     Please note that the license type can be one of "composer", "professional" or
    "cluster";
     '';
  licenseFile = config.psxe.licenseFile or (throw (licenseHelpMsg "missing license file"));

  components_ = [
    "intel-mkl-cluster*"
    "intel-mkl-common*"
    "intel-mkl-core*"
  #] ++ stdenv.lib.optionals (stdenv.lib.versionOlder "2017.99.999" version) [ ""
  ];

  extract = pattern: ''
    for rpm in $(ls $build/rpm/${pattern}.rpm | grep -v 32bit); do
      echo "Extracting: $rpm"
      ${rpm}/bin/rpm2cpio $rpm | ${cpio}/bin/cpio -ivd
    done
  '';

self = stdenv.mkDerivation rec {
  inherit version;
  name = "intel-mkl-${version}";

  src = fetchannex { inherit url sha256; };

  nativeBuildInputs= [ file patchelf ];

  outputs = [ "out" "benchmarks" ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    set -xv
    export build=$PWD
    mkdir $out
    cd $out
    echo "${stdenv.lib.concatStringsSep "+" components_}"
    ${stdenv.lib.concatMapStringsSep "\n" extract components_}

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
      "application/executable"|"application/x-executable"|"application/x-pie-executable")
        echo "Patching executable: $f"
        patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib:{redist}/lib:${mpi}/lib:${mpi}/lib/release_mt $f || true
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

    ln -s $out/mkl/lib/intel64_lin $out/lib
    ln -s $out/mkl/include $out/include

    mv $out/mkl/benchmarks $benchmarks
    mkdir -p $benchmarks/bin
    ln -s $benchmarks/mp_linpack/xhpl_intel64_dynamic $benchmarks/bin
  '';

  enableParallelBuilding = true;

  passthru = {
    lib = self; # compatibility with gcc, so that `stdenv.cc.cc.lib` works on both
    isIntel = true;
    hardeningUnsupportedFlags = [ "stackprotector" ];
    langFortran = true;
  } // stdenv.lib.optionalAttrs stdenv.isLinux {
    inherit gcc;
  };

  meta = {
    description = "Intel mkl library ${version}";
    maintainers = [ stdenv.lib.maintainers.dguibert ];
    platforms = stdenv.lib.platforms.linux;
  };
};
in self
