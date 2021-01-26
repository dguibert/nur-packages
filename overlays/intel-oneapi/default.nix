final: prev: with prev;
let
  releases = {
    "mpi.2021.1.1" = { irc_id=17397; build=76;};
    #"tbb.'2021.1.1': {'irc_id': '17378', build: '119'}}
    # mkl.'2021.1.1': {'irc_id': '17402', build: '52'}}
    "compilers.2021.1.0" = { irc_id=17427; build=2684; dir_name="compiler"; };
  };
  versions = {
    "mpi.2021.1.1" = { sha256="8b7693a156c6fc6269637bef586a8fd3ea6610cac2aae4e7f48c1fbb601625fe"; url_name="mpi_oneapi"; };
    # tbb version('2021.1.1', sha256='535290e3910a9d906a730b24af212afa231523cf13a668d480bade5f2a01b53b'
    #mkl.version('2021.1.1', sha256='818b6bd9a6c116f4578cda3151da0612ec9c3ce8b2c8a64730d625ce5b13cc0c', expand=False)
    "compilers.2021.1.0" = { sha256="666b1002de3eab4b6f3770c42bcf708743ac74efeba4c05b0834095ef27a11b9"; url_name="HPCKit"; };
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
  #intel.oneapi.lin.dpcpp-cpp-common.runtime,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-common,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-cfg,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-plugin-file,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro.eclipse-plugin-integration,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-compiler-pro,v=2021.1.1-189
  #intel.oneapi.lin.dpcpp-cpp-pro-fortran-compiler-common,v=2021.1.1-189
  #intel.oneapi.lin.hpckit.getting_started,v=2021.1.0-2684
  #intel.oneapi.lin.hpckit.product,v=2021.1.0-2684
  #intel.oneapi.lin.ifort-compiler,v=2021.1.1-189
  #intel.oneapi.lin.inspector,v=2021.1.1-42
  #intel.oneapi.lin.itac,v=2021.1.1-42
  #intel.oneapi.lin.mpi.devel,v=2021.1.1-76
  #intel.oneapi.lin.mpi.runtime,v=2021.1.1-76
  #intel.oneapi.lin.oneapi-common.licensing,v=2021.1.1-60
  #intel.oneapi.lin.oneapi-common.vars,v=2021.1.1-60
  #intel.oneapi.lin.openmp,v=2021.1.1-189
  #intel.oneapi.lin.tbb.devel,v=2021.1.1-119
  #intel.oneapi.lin.tbb.runtime,v=2021.1.1-119
  components = {
    mpi = [
      "intel.oneapi.lin.mpi.devel"
    ];
    compilers = [
      "intel.oneapi.lin.compilers-common.runtime,v=*"#2021.1.1-189
      "intel.oneapi.lin.compilers-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-common.runtime,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-compiler-pro,v=*"#2021.1.1-189
      "intel.oneapi.lin.dpcpp-cpp-pro-fortran-compiler-common,v=*"#2021.1.1-189
      "intel.oneapi.lin.ifort-compiler,v=*"#2021.1.1-189
    ];
  };
  # tbb', components='intel.oneapi.lin.tbb.devel', releases=releases, url_name='tbb_oneapi')
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
      7za x -y packages/${pattern}/cupPayload.cup
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
    #ls
    #patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2 ./bootstrapper
    #patchelf --set-rpath "\$ORIGIN:${zlib}/lib:${stdenv.cc.cc.lib}/lib" ./bootstrapper
    #ldd ./bootstrapper
    #for lib in *.so; do
    #  patchelf --set-rpath "\$ORIGIN:${zlib}/lib:${stdenv.cc.cc.lib}/lib" $lib
    #done
    nativeBuildInputs= [ file patchelf ];

    dontPatchELF = true;
    dontStrip = true;
    noAuditTmpdir = true;

    installPhase = ''
      ${stdenv.lib.concatMapStringsSep "\n" extract components."${name}"}
      # bash('./%s' % self._oneapi_file(version, release),
      # '-s', '-a', '-s', '--action', 'install',
      # '--eula', 'accept',
      # '--components',
      # self._components,
      # '--install-dir', prefix)
      mv -v _installdir/${dir_name}/*/linux $out

    '';
  } // attrs);

  compilers_attrs = {
    preFixup = ''
      # Fixing man path
      rm -rf $out/documentation
      rm -rf $out/man

      echo "Patching rpath and interpreter..."
      for f in $(find $out/bin -type f -executable); do
          echo "    Patching executable: $f"
          patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64:${zlib}/lib $f || true
      done
      for f in $(find $out/lib $out/compiler -type f -executable); do
        type="$(file -b --mime-type $f)"
        case "$type" in
        "application/executable"|"application/x-executable")
          echo "    Patching executable: $f"
          patchelf --set-interpreter $(echo ${stdenv.cc.libc.out}/lib/ld-linux*.so.2) --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64 $f || true
          ;;
        "application/x-sharedlib"|"application/x-pie-executable")
          echo "    Patching library   : $f"
          patchelf --set-rpath ${stdenv.cc.libc.out}/lib:${gcc.cc}/lib:${gcc.cc.lib}/lib:\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/../compiler/lib/intel64 $f || true
          ;;
        *)
          echo "Not Patching           : $f ($type)"
          ;;
        esac
      done
    '';
  };


in {
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
  oneapiPackages_2021_1_0 = {
    unwrapped = oneapiPackage {
      name = "compilers";
      version = "2021.1.0";
    } compilers_attrs;
  };
}
