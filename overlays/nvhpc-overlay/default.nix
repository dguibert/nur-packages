final: prev:
let
  wrapCCWith = with prev; { cc
    , # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      bintools ? if targetPlatform.isDarwin then darwin.binutils else binutils
    , libc ? bintools.libc
    , ...
    } @ extraArgs:
      callPackage ./build-support/cc-wrapper (let self = {
    nativeTools = targetPlatform == hostPlatform && stdenv.cc.nativeTools or false;
    nativeLibc = targetPlatform == hostPlatform && stdenv.cc.nativeLibc or false;
    nativePrefix = stdenv.cc.nativePrefix or "";
    noLibc = !self.nativeLibc && (self.libc == null);

    isGNU = cc.isGNU or false;
    isClang = cc.isClang or false;

    inherit cc bintools libc;
  } // extraArgs; in self);

  nvhpcPackages = { version, sha256 }: rec {
    unwrapped = prev.callPackage ./nvhpc {
      inherit version sha256;
    };
    nvhpc = wrapCCWith rec {
      cc = unwrapped;
      extraPackages = [
      ];
      extraBuildCommands = ''
      ccLDFlags+=" -L${prev.numactl}/lib -rpath,${prev.numactl}/lib"
      echo "$ccLDFlags" > $out/nix-support/cc-ldflags
      '';
    };
    stdenv = prev.overrideCC prev.stdenv nvhpc;
  };

in
{
  nvhpcPackages_20_9 = nvhpcPackages {
    version="20.9";
    sha256 ="0n7xdyqzsixsyahk604akn5z5dpyzyw1c6jk7mgiaj0v5rv7v84g";
  };
  nvhpcPackages_21_5 = nvhpcPackages {
    version="21.5";
    sha256 ="0bahwqfqz5j93s9gifsbgdbr1wafc6np4hlhrbjvv7q9cbbcs966";
  };
}

