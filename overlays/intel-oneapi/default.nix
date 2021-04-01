final: prev: with prev;
let
  releases = {
    "mpi.2021.1.1" = { irc_id=17397; build=76; dir_name="mpi"; };
    "mpi.2021.2.0" = { irc_id=17729; build=215; dir_name="mpi"; }; # https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17729/l_mpi_oneapi_p_2021.2.0.215_offline.sh

    #"tbb.'2021.1.1': {'irc_id': '17378', build: '119'}}
    # mkl.'2021.1.1': {'irc_id': '17402', build: '52'}}
    # mkl.'2021.2.0': {'irc_id': '17757', build: '296'}} # https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/17757/l_onemkl_p_2021.2.0.296_offline.sh

    ## https://software.intel.com/content/www/us/en/develop/tools/oneapi/hpc-toolkit/download.html?operatingsystem=linux&distributions=webdownload&options=offline
    "compilers.2021.1.0" = { irc_id=17427; build=2684; dir_name="compiler"; }; # https://registrationcenter-download.intel.com/akdlm/irc_nas/17427/l_HPCKit_p_2021.1.1.2684_offline.sh
    "compilers.2021.2.0" = { irc_id=17764; build=2997; dir_name="compiler"; }; # https://registrationcenter-download.intel.com/akdlm/irc_nas/17764/l_HPCKit_p_2021.2.0.2997_offline.sh
  };
  versions = {
    "mpi.2021.1.1" = { sha256="8b7693a156c6fc6269637bef586a8fd3ea6610cac2aae4e7f48c1fbb601625fe"; url_name="mpi_oneapi"; };
    "mpi.2021.2.0" = { sha256="sha256-0NTN0R7a/y5yheOPU33vzP8443owZ8AvSvQ6NimtSqM="; url_name="mpi_oneapi"; };

    # tbb version('2021.1.1', sha256='535290e3910a9d906a730b24af212afa231523cf13a668d480bade5f2a01b53b'
    #mkl.version('2021.1.1', sha256='818b6bd9a6c116f4578cda3151da0612ec9c3ce8b2c8a64730d625ce5b13cc0c', expand=False)

    "compilers.2021.1.0" = { sha256="666b1002de3eab4b6f3770c42bcf708743ac74efeba4c05b0834095ef27a11b9"; url_name="HPCKit"; };
    "compilers.2021.2.0" = { sha256="sha256-WrxH4zqXQVwi2pGEYLuQbcrShVIzrjg/ztpWZSJWLEo="; url_name="HPCKit"; };
  };

  #intel.installer.oneapi.linux.installer,v=4.0.4-261
  #intel.installer.packagemanager.linux,v=4.0.0-136.beta
  #intel.oneapi.lin.clck,v=2021.1.1-68
  #intel.oneapi.lin.condaindex,v=2021.1.1-58
  #intel.oneapi.lin.dev-utilities.eclipse-file,v=2021.1.1-197
  #intel.oneapi.lin.dev-utilities.eclipse-integration,v=2021.1.1-197
  #intel.oneapi.lin.dev-utilities.plugins,v=2021.1.1-197
  #intel.oneapi.lin.dev-utilities,v=2021.1.1-197
  #intel.oneapi.lin.dpcpp-compiler.eclipse-cfg,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-compiler.eclipse-plugin-file,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-compiler.eclipse-plugin-integration,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-cfg,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-plugin-file,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-plugin-integration,v=2021.1.1-189
  #intel.oneapi.lin.hpckit.getting_started,v=2021.1.0-2684
  #intel.oneapi.lin.hpckit.product,v=2021.1.0-2684
  #intel.oneapi.lin.inspector,v=2021.1.1-42
  #intel.oneapi.lin.itac,v=2021.1.1-42
  #intel.oneapi.lin.oneapi-common.licensing,v=2021.1.1-60
  #intel.oneapi.lin.oneapi-common.vars,v=2021.1.1-60
  components = {
    mpi = [
      "intel.oneapi.lin.mpi.devel,v=*"#2021.1.1-76
      "intel.oneapi.lin.mpi.runtime,v=*"#2021.1.1-76
    ];
    compilers = [
      "intel.oneapi.lin.compilers-common.runtime,v=*"#2021.1.1-189
      "intel.oneapi.lin.compilers-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-common.runtime,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-compiler-pro,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-pro-fortran-compiler-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.ifort-compiler,v=*"#2021.1.1-189
      #intel.oneapi.lin.openmp,v=2021.1.1-189
    ];
  };
  # tbb', components='intel.oneapi.lin.tbb.devel', releases=releases, url_name='tbb_oneapi')
  #intel.oneapi.lin.tbb.devel,v=2021.1.1-119
  #intel.oneapi.lin.tbb.runtime,v=2021.1.1-119
  # mkl', components='intel.oneapi.lin.mkl.devel', releases=releases, url_name='onemkl')

  oneapiPackage = { name
    , version
  }: attrs: let
    pname = "oneapi-${name}";
    url_name = versions."${name}.${version}".url_name;
    sha256 = versions."${name}.${version}".sha256;
    release_build = toString releases."${name}.${version}".build;
    irc_id = toString releases."${name}.${version}".irc_id;
    dir_name = releases."${name}.${version}".dir_name;

    _oneapi_file = "l_${url_name}_p_${version}.${release_build}_offline.sh";
    #self._url_name, version, release['build'])";

    extract = pattern: ''
      case "${pattern}" in
      *runtime*)
        mkdir -p runtime; cd runtime
        7za l    ../packages/${pattern}/cupPayload.cup
        7za x -y ../packages/${pattern}/cupPayload.cup
        cd -
        ;;
      *)
        mkdir -p out; cd out
        7za l    ../packages/${pattern}/cupPayload.cup
        7za x -y ../packages/${pattern}/cupPayload.cup
        cd -
        ;;
      esac
    '';
  in prev.stdenv.mkDerivation ({
    inherit pname version;

    src = prev.fetchurl {
      url = "https://registrationcenter-download.intel.com/akdlm/irc_nas/${irc_id}/${_oneapi_file}";
      inherit sha256;
    };

    buildInputs = with final; [
      p7zip
    ];

    unpackPhase = ''
      sh $src --extract-folder oneapi -x
      cd oneapi/l_${url_name}_p_${version}.${release_build}_offline
    '';

    nativeBuildInputs= [ file patchelf ];

    dontPatchELF = true;
    dontStrip = true;
    noAuditTmpdir = true;

    installPhase = ''
      ${lib.concatMapStringsSep "\n" extract components."${name}"}
      # bash('./%s' % self._oneapi_file(version, release),
      # '-s', '-a', '-s', '--action', 'install',
      # '--eula', 'accept',
      # '--components',
      # self._components,
      # '--install-dir', prefix)
    '';
  } // attrs);

  mpi_attrs = {
    outputs = [ "out" "runtime" ];

    preFixup = ''
      mv out/_installdir/mpi/* $out

      mv runtime/_installdir/mpi/* $runtime

      for f in $(find $out $runtime -type f -executable); do
        type="$(file -b --mime-type $f)"
        case "$type" in
        "application/executable"|"application/x-executable")
          echo "    Patching executable: $f"
          patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib $f || true
          ;;
        "application/x-sharedlib"|"application/x-pie-executable")
          echo "    Patching library   : $f"
          patchelf --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib $f || true
          ;;
        *)
          echo "Not Patching           : $f ($type)"
          ;;
        esac
      done

      (cd $runtime; find -type d -exec mkdir -vp $out/{} \; )
      (cd $runtime; find -type f -exec ln -vsf $runtime/{} $out/{} \; )

    '';
  };

  compilers_attrs = {
    langFortran = true;
    isOneApi = true;

    outputs = [ "out" "runtime" ];

    preFixup = ''
      mv out/_installdir/compiler/*/linux $out

      mv runtime/_installdir/compiler/*/linux $runtime
      # Fixing man path
      rm -rf $out/documentation
      rm -rf $out/man

      echo "Patching rpath and interpreter..."
      for f in $(find $out/bin $runtime/bin -type f -executable); do
          echo "    Patching executable: $f"
          patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:${zlib}/lib:$runtime/lib:$runtime/compiler/lib/intel64:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64 $f || true
      done
      for f in $(find $out/lib $out/compiler $runtime/lib $runtime/compiler -type f -executable); do
        type="$(file -b --mime-type $f)"
        case "$type" in
        "application/executable"|"application/x-executable")
          echo "    Patching executable: $f"
          patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:$runtime/lib:$runtime/compiler/lib/intel64:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64 $f || true
          ;;
        "application/x-sharedlib"|"application/x-pie-executable")
          echo "    Patching library   : $f"
          patchelf --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:$runtime/lib:$runtime/compiler/lib/intel64:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64 $f || true
          ;;
        *)
          echo "Not Patching           : $f ($type)"
          ;;
        esac
      done

      (cd $runtime; find -type d -exec mkdir -vp  $out/{} \; )
      (cd $runtime; find -type f -exec ln -vsf $runtime/{} $out/{} \; )
      (cd $runtime/compiler/lib; ln -sv intel64_lin intel64)
    '';
  };

  wrapCCWith = { cc
    , # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      bintools ? if pkgs.targetPlatform.isDarwin then pkgs.darwin.binutils else pkgs.binutils
    , libc ? bintools.libc or pkgs.stdenv.cc.libc
    , ...
    } @ extraArgs:
      pkgs.callPackage ./build-support/cc-wrapper (let self = {
    nativeTools = pkgs.targetPlatform == pkgs.hostPlatform && pkgs.stdenv.cc.nativeTools or false;
    nativeLibc = pkgs.targetPlatform == pkgs.hostPlatform && pkgs.stdenv.cc.nativeLibc or false;
    nativePrefix = pkgs.stdenv.cc.nativePrefix or "";
    noLibc = !self.nativeLibc && (self.libc == null);

    isGNU = cc.isGNU or false;
    isClang = cc.isClang or false;
    isIntel = false;
    isOneApi = true;

    inherit cc bintools libc;
  } // extraArgs; in self);

  mkExtraBuildCommands = release_version: cc: runtime: ''
    rsrc="$out/resource-root"
    mkdir "$rsrc"

    if test ! -e ${cc}/lib/clang/${release_version}; then
      exit 1
    fi

    ln -s "${cc}/lib/clang/${release_version}/include" "$rsrc"
    ln -s "${runtime}/lib" "$rsrc/lib"
    echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
    echo "-L=${runtime}/lib" >> $out/nix-support/cc-cflags
  '' + prev.lib.optionalString prev.stdenv.targetPlatform.isLinux ''
    echo "--gcc-toolchain=${gccForLibs} -B${gccForLibs}" >> $out/nix-support/cc-cflags
  '';

in rec {
### For quick turnaround debugging, copy instead of install
### copytree('/opt/intel/oneapi/compiler', path.join(prefix, 'compiler'),
###          symlinks=True)
##rpath_dirs = ['lib',
##'lib/x64',
##'lib/emu',
##'lib/oclfpga/host/linux64/lib',
##'lib/oclfpga/linux64/lib',
##'compiler/lib/intel64_lin',
##'compiler/lib']
##patch_dirs = ['compiler/lib/intel64_lin',
##'compiler/lib/intel64',
##'bin']
##eprefix = path.join(prefix, 'compiler', 'latest', 'linux')
##rpath = ':'.join([path.join(eprefix, c) for c in rpath_dirs])
##for pd in patch_dirs:
##for file in glob.glob(path.join(eprefix, pd, '*')):
### Try to patch all files, patchelf will do nothing if
### file should not be patched
##subprocess.call(['patchelf', '--set-rpath', rpath, file])
  oneapiPackages_2021_1_0 = with oneapiPackages_2021_1_0; {
    unwrapped = oneapiPackage { name = "compilers"; version = "2021.1.0"; } compilers_attrs;

    compilers = wrapCCWith {
      cc = unwrapped;
      #extraPackages = [ /*redist*/ final.which final.binutils unwrapped ];
      extraPackages = [ unwrapped.runtime ];
      extraBuildCommands = mkExtraBuildCommands "12.0.0" unwrapped unwrapped.runtime;
    };

    mpi = oneapiPackage { name = "mpi"; version = "2021.1.1"; } mpi_attrs;

    /* Return a modified stdenv that uses Intel compilers */
    stdenv = let stdenv_=pkgs.overrideCC pkgs.stdenv compilers; in stdenv_ // {
      mkDerivation = args: stdenv_.mkDerivation (args // {
        CC="icx";
        CXX="icpx";
        FC="ifx";
        F77="ifx";
        F90="ifx";
        #phases = (args.phases or []) ++ [ "fixupPhase" ];
        #postFixup = "${args.postFixup or ""}" + ''
        #set -x
        #storeId=$(echo "${compilers}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
        #find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
        #storeId=$(echo "${unwrapped}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
        #find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
        #set +x
        #'';
      });
    };
  };

  oneapiPackages_2021_2_0 = with oneapiPackages_2021_2_0; {
    unwrapped = oneapiPackage { name = "compilers"; version = "2021.2.0"; } compilers_attrs;

    compilers = wrapCCWith {
      cc = unwrapped;
      #extraPackages = [ /*redist*/ final.which final.binutils unwrapped ];
      extraPackages = [ unwrapped.runtime ];
      extraBuildCommands = mkExtraBuildCommands "12.0.0" unwrapped unwrapped.runtime;
    };

    mpi = oneapiPackage { name = "mpi"; version = "2021.2.0"; } mpi_attrs;

    /* Return a modified stdenv that uses Intel compilers */
    stdenv = let stdenv_=pkgs.overrideCC pkgs.stdenv compilers; in stdenv_ // {
      mkDerivation = args: stdenv_.mkDerivation (args // {
        CC="icx";
        CXX="icpx";
        FC="ifx";
        F77="ifx";
        F90="ifx";
        #phases = (args.phases or []) ++ [ "fixupPhase" ];
        #postFixup = "${args.postFixup or ""}" + ''
        #set -x
        #storeId=$(echo "${compilers}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
        #find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
        #storeId=$(echo "${unwrapped}" | sed -n "s|^$NIX_STORE/\\([a-z0-9]\{32\}\\)-.*|\1|p")
        #find $out -type f -print0 | xargs -0 sed -i -e  "s|$NIX_STORE/$storeId-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g"
        #set +x
        #'';
      });
    };
  };
}
