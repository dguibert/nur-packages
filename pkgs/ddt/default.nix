{ stdenv, lib, fetchurl, licenceFile ? null, patchelf
, fontconfig, libpng12, libICE, ncurses, qt4, libSM, libX11, libXau, libXext, libXpm, libXrender, zlib
, makeWrapper, gcc
}:

#assert licenceFile != null;

stdenv.mkDerivation rec {
  name = "ddt-19.1.4";
  src = fetchurl {
    # http://content.allinea.com/downloads/arm-forge-20.0.3-Suse-15.0-x86_64.tar
    url = "http://content.allinea.com/downloads/arm-forge-19.1.4-Suse-15.0-x86_64.tar";
    sha256 = "0pxg44rp9zk0dg4czhj784s2k36da3fxr8nin72lh3ilfdh0bxbs";
  };

  buildInputs = [ patchelf makeWrapper ];

  rPath = "${lib.makeLibraryPath [fontconfig libpng12 libICE ncurses qt4 libSM libX11 libXau libXext libXpm libXrender zlib ]}";
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    tar xvf forge.tgz
    mkdir -p $out

    cp -r bin $out
    cp -r libexec $out

    for f in $out/bin/* $out/libexec/*; do
    patchelf \
      --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath $(patchelf --print-rpath $f):$out/lib:${gcc.cc}/lib64:${gcc.cc}/lib:${rPath}: \
      $f || true
    done
    for f in $out/lib/*; do
    patchelf \
      --set-rpath $(patchelf --print-rpath $f):$out/lib:${gcc.cc}/lib64:${gcc.cc}/lib:${rPath}: \
      $f || true
    done
    wrapProgram $out/libexec/ddt.bin --prefix LD_LIBRARY_PATH : ${rPath}
    wrapProgram $out/bin/ddt-debugger --prefix LD_LIBRARY_PATH : ${rPath}
    # remove QT libraries provide by our Qt version
    rm lib/libQt*
    cp -r lib $out
    cp -r help $out
    cp -r doc $out

    cp -r icons $out

    #cp {licenceFile} $out/Licence
  '';

  meta = {
    homepage = "http://www.allinea.com/products/ddt";
    decription = "Allinea DDT - the debugging tool for parallel computing";
  };
}
