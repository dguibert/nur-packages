{ stdenv, requireFile, autoPatchelfHook }:

stdenv.mkDerivation {
  name = "maqao-2.10.11";
  src = requireFile {
    name = "maqao-2.10.11.tar.gz";
    url = "maqao-2.10.11.tar.gz";
    sha256 = "0qxmxqx3dr986hbx3y817jlmnk2ikxxd1vf01nycx1j4caqkmslz";
  };

  buildInputs = [ autoPatchelfHook ];

  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp bin/maqao $out/bin/

    mkdir -p $out/lib
    cp lib/* $out/lib/
  '';
}
