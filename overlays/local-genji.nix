self: super:
let
  overlay = (super.lib.composeOverlays [
   (import ./default.nix).default
   (import ./default.nix).nix-home-nfs-robin-ib-bguibertd
   (self: super: {
    go_bootstrap = super.go_bootstrap.overrideAttrs (attrs: {
      doCheck = false;
      installPhase = ''
        mkdir -p "$out/bin"
        export GOROOT="$(pwd)/"
        export GOBIN="$out/bin"
        export PATH="$GOBIN:$PATH"
        cd ./src
        ./make.bash
      '';
    });
     go_1_10 = super.go_1_10.overrideAttrs (attrs: {
      doCheck = false;
      installPhase = ''
        mkdir -p "$out/bin"
        export GOROOT="$(pwd)/"
        export GOBIN="$out/bin"
        export PATH="$GOBIN:$PATH"
        cd ./src
        ./make.bash
      '';
    });
    go_1_11 = super.go_1_11.overrideAttrs (attrs: {
      doCheck = false;
    });
   })
  ]);
in overlay self super
