# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> {} }:

rec {
  # The `lib`, `modules`, and `overlay` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  envs = import ./envs { inherit pkgs overlays lib; };

  adapters = import ./pkgs/stdenv/adapters.nix pkgs;
  inherit (adapters) optimizePackage withOpenMP optimizedStdEnv;

  example-package = pkgs.callPackage ./pkgs/example-package { };
  # some-qt5-package = pkgs.libsForQt5.callPackage ./pkgs/some-qt5-package { };
  # ...
  dyninst = pkgs.callPackage ./pkgs/dyninst { };
  palabos = pkgs.callPackage ./pkgs/palabos { };
  otf2 = pkgs.callPackage ./pkgs/otf2 { };

  score-p = pkgs.callPackage ./pkgs/score-p {
    inherit otf2;
    inherit cubew;
    inherit cubelib;
  };
  caliper = pkgs.callPackage ./pkgs/caliper {
    inherit dyninst;
  };
  cubew = pkgs.callPackage ./pkgs/cubew { };
  cubelib = pkgs.callPackage ./pkgs/cubelib { };
  cubegui = pkgs.callPackage ./pkgs/cubegui { inherit cubelib; };
  dwm = pkgs.dwm.override {patches = [
    ./pkgs/dwm/0001-dwm-pertag-20170513-ceac8c9.patch
    ./pkgs/dwm/0002-dwm-systray-20180314-3bd8466.diff.patch
    ./pkgs/dwm/0003-config.h-azerty.patch
    ./pkgs/dwm/0004-config.h-audio-controls.patch
    ./pkgs/dwm/0005-light-solarized-theme.patch
    ./pkgs/dwm/0006-config-support-shortcuts-for-vbox-inside-windows.patch
    ./pkgs/dwm/0007-xpra-as-float.patch
    ./pkgs/dwm/0008-qtpass-as-float.patch
    ./pkgs/dwm/0009-pineentry-as-float.patch
  ];};

  gitAndTools = pkgs.gitAndTools // {
    git-credential-password-store = pkgs.callPackage ./pkgs/git-credential-password-store { };
  };

  jobs = pkgs.callPackage ./pkgs/jobs {
    inherit stream;
    #scheduler = jobs.scheduler_slurm;
    scheduler = jobs.scheduler_local;
  };

  hpcg = pkgs.callPackage ./pkgs/hpcg { };
  hpl = pkgs.callPackage ./pkgs/hpl { };

  lmod = pkgs.callPackage ./pkgs/lmod {
      inherit (pkgs.luaPackages) luafilesystem;
      inherit luaposix;
    };
    luaposix = pkgs.luaPackages.buildLuaPackage rec {
      name = "luaposix-32";

      buildInputs = [ pkgs.perl ];
      src = pkgs.fetchurl {
        url = "https://github.com/luaposix/luaposix/archive/release-v32.tar.gz";
        sha256 = "09dbbde825fd9b76a8a1f6a80920434f8629a392cd1840021ed4b95b21fcf073";
      };
      meta = {
        homepage = "https://github.com/luaposix/luaposix";
      };
    };

  lo2s = pkgs.callPackage ./pkgs/lo2s { inherit otf2; };
  lulesh = pkgs.callPackage ./pkgs/lulesh { };

  must = pkgs.callPackage ./pkgs/must { inherit dyninst; };
  muster = pkgs.callPackage ./pkgs/muster { };
  nemo_36 = pkgs.callPackage ./pkgs/nemo/3.6.nix { xios = xios_10; };
  nemo = pkgs.callPackage ./pkgs/nemo { };
  nix-patchtools = pkgs.callPackage ./pkgs/nix-patchtools { };
  ravel = pkgs.callPackage ./pkgs/ravel {
    inherit otf2;
    inherit muster;
  };
  st = pkgs.st.override {patches = [
    ./pkgs/st/0001-theme-from-base16-c_header.patch
    #./pkgs/st/0002-Update-base-patch-to-0.8.1.patch
    ./pkgs/st/0003-Show-bold-not-as-bright.patch
    (pkgs.fetchpatch { url="https://st.suckless.org/patches/clipboard/st-clipboard-20180309-c5ba9c0.diff"; sha256="1f7fgzvbiikdm98icmh34abjha361nvf6a9r7lq38lhnwlyw12a9"; })
  ];};
  xios_10 = pkgs.callPackage ./pkgs/xios/1.0.nix { };
  xios = pkgs.callPackage ./pkgs/xios { };

  # miniapps
  miniapp-ping-pong = pkgs.callPackage ./pkgs/miniapp-ping-pong { inherit caliper; };
  stream = pkgs.callPackage ./pkgs/stream { };

}

