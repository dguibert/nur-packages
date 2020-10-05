{ fetchurl, stdenv }:

let

  buildFirefoxXpiAddon =
    { pname, version, addonId, url, sha256, meta, ... }:
      stdenv.mkDerivation {
        name = "${pname}-${version}";

        inherit meta;

        src = fetchurl {
          inherit url sha256;
        };

        preferLocalBuild = true;
        allowSubstitutes = false;

        buildCommand = ''
          dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
          mkdir -p "$dst"
          install -v -m644 "$src" "$dst/${addonId}.xpi"
        '';
      };

  # git clone https://gitlab.com/rycee/nixpkgs-firefox-addons
  # cd nixpkgs-firefox-addons; nix-build
  # ./nixpkgs-firefox-addons/result/bin/nixpkgs-firefox-addons addons.json  generated-firefox-addons.nix
  packages = import ./generated-firefox-addons.nix {
    inherit buildFirefoxXpiAddon fetchurl stdenv;
  };

in

packages // {
  inherit buildFirefoxXpiAddon;
}
