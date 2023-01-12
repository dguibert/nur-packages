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
        overlays =  upstream.legacyPackages.${system}.overlays ++ [
          upstream.overlays.cluster
          upstream.overlays.store-spartan
        ];
        config.allowUnfree = true;
        config.replaceStdenv = import "${upstream}/stdenv.nix";
    };
  in (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
    legacyPackages = nixpkgsFor system;
  })) // {
    lib = nixpkgs.lib;
  };
}
