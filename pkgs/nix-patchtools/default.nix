{
  stdenv,
  fetchFromGitHub,
  file,
  getopt,
}:
stdenv.mkDerivation {
  pname = "autopatchelf";
  version = "unstable-2019-06-15";
  src = fetchFromGitHub {
    owner = "svanderburg";
    repo = "nix-patchtools";
    rev = "6cc6fa4e0d8e1f24be155f6c60af34c8756c9828";
    hash = "sha256-anuSZw0wcKtTxszBZh2Ob/eOftixEZzrNC1sCaQzznk=";
  };
  buildPhase = ''
    mkdir -p $out/bin
    cp autopatchelf $out/bin/autopatchelf
    sed -i \
      -e "s|file |${file}/bin/file |" \
      -e "s|getopt |${getopt}/bin/getopt |" $out/bin/autopatchelf
    chmod +x $out/bin/autopatchelf
    patchShebangs $out/bin
  '';
}
