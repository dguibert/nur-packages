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

  armPackages = { version, sha256 }: rec {
    inherit (super.callPackage ./arm-compiler-for-hpc {
      inherit version sha256;
    })
      unwrapped
      armpl
    ;
    arm = wrapCCWith rec {
      cc = unwrapped;
      extraPackages = [
      ];
      #extraBuildCommands = mkExtraBuildCommands cc;
    };
    stdenv = super.overrideCC super.stdenv arm;
  };

in
{
  armPackages_190 = armPackages {
    version="19.0";
    sha256 ="1c8843c6fd24ea7bfb8b4847da73201caaff79a1b8ad89692a88d29da0c5684e";
  };
  armPackages_191 = armPackages {
    version="19.1";
    sha256 ="0hps82y7ga19n38n2fkbp4jm21fgbxx3ydqdnh0rfiwmxhvya07a";
  };
  armPackages_192 = armPackages {
    version="19.2";
    sha256 ="1zdn7dq05c7fjnh1wfgxkd5znrxy0g3h0kpyn3gar6n2qdl0j22v";
  };
}
