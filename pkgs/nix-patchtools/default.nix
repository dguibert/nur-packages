{ stdenv, fetchFromGitHub, file, getopt}:

stdenv.mkDerivation {
  name = "autopatchelf";
  #src = /home/dguibert/code/nix-patchtools;
  src = fetchFromGitHub {
    owner = "dguibert";
    repo = "nix-patchtools";
    rev = "dg/aarch64";
    sha256 = "sha256:0yff6fj0jv1d6kmrq4div1z8xxvgiqfndhfcqr9snw1h1mkr4yva";
  };
  buildCommand = ''
    mkdir -p $out/bin
    cp $src/autopatchelf $out/bin/autopatchelf
    sed -i \
      -e "s|file |${file}/bin/file |" \
      -e "s|getopt |${getopt}/bin/getopt |" $out/bin/autopatchelf
    chmod +x $out/bin/autopatchelf
    patchShebangs $out/bin
  '';
}

