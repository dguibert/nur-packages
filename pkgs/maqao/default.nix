{ stdenv, requireFile, autoPatchelfHook }:

stdenv.mkDerivation {
  name = "maqao-2.9.16";
  src = requireFile {
    name = "maqao-2.9.16.tar.gz";
    url = "maqao-2.9.16.tar.gz";
    sha256 = "1nh61gcn1rnq4qga9j06ngcd7m4ibmk4fhxnhvgv9l8ppy79qpsy";
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
