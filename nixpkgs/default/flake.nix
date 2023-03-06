{
  description = "A flake for building my NUR packages";

  ## dev
  #inputs.upstream.url = "path:../..";
  inputs.upstream.url = "github:dguibert/nur-packages/master";
  inputs.nixpkgs.follows = "upstream/nixpkgs";
  inputs.nix.follows = "upstream/nix";
  inputs.flake-utils.follows = "upstream/flake-utils";

  outputs = { self, nixpkgs, nix, flake-utils, upstream, ... }@inputs: let
    inherit (self) outputs;
    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays =  upstream.legacyPackages.${system}.overlays ++ [
          (final: prev: {
            libuv = prev.libuv.overrideAttrs (o: {
              doCheck = false;
              doInstallCheck = false;
            });
          })
        ];
        config.allowUnfree = true;
        config.replaceStdenv = import "${upstream}/stdenv.nix";
    };
  in (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {
    legacyPackages = nixpkgsFor system;

    apps = import ../../apps {
      inherit (self) lib;
      inherit system inputs outputs;
    };

    checks = inputs.flake-utils.lib.flattenTree (import ../../checks { inherit inputs outputs system;
                                                                       pkgs = self.legacyPackages.${system};
                                                                       lib = inputs.nixpkgs.lib; });
  })) // {
    lib = nixpkgs.lib;

    overlays = upstream.overlays;
  };
}
