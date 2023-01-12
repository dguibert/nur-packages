{
  description = "A flake for building my NUR packages";

  inputs.upstream.url = "path:../..";
  inputs.nixpkgs.follows = "upstream/nixpkgs";
  inputs.nix.follows = "upstream/nix";
  inputs.flake-utils.follows = "upstream/flake-utils";

  outputs = { self, nixpkgs, nix, flake-utils, upstream, ... }: let
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  [
          upstream.overlays.default
          upstream.overlays.extra-builtins
          nix.overlays.default
        ];
        config.allowUnfree = true;
        config.replaceStdenv = import "${upstream}/stdenv.nix";
    };
  in (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {
    legacyPackages = nixpkgsFor system;
  }));
}
