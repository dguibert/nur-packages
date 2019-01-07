self: super:
let
  wrapCCWith = with super; { cc
    , # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      bintools ? if targetPlatform.isDarwin then darwin.binutils else binutils
    , libc ? bintools.libc
    , ...
    } @ extraArgs:
      callPackage ../flang-overlay/build-support/cc-wrapper (let self = {
    nativeTools = targetPlatform == hostPlatform && stdenv.cc.nativeTools or false;
    nativeLibc = targetPlatform == hostPlatform && stdenv.cc.nativeLibc or false;
    nativePrefix = stdenv.cc.nativePrefix or "";
    noLibc = !self.nativeLibc && (self.libc == null);

    isGNU = cc.isGNU or false;
    isClang = cc.isClang or false;

    inherit cc bintools libc;
  } // extraArgs; in self);

  aoccPackages = { version, sha256 }: rec {
    unwrapped = super.callPackage ./aocc {
      inherit version sha256;
    };
    aocc = wrapCCWith rec {
      cc = unwrapped;
      extraPackages = [
      ];
      #extraBuildCommands = mkExtraBuildCommands cc;
    };
  };

in
{
  aoccPackages_121 = aoccPackages {
    version="1.2.1";
    sha256 ="008w6algs72d3klkdpaj95nz6ax1y2dyp4zflv4xpz3ybbc7whar";
  };
  aoccPackages_130 = aoccPackages {
    version="1.3.0";
    sha256 ="0zi1j23h9gmw62d883m3yfa9hjkpznky5jlc4w2d34mmj4njwmms";
  };
}
