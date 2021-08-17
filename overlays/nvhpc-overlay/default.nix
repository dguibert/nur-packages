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

  nvhpcPackages = { version, url, sha256 }: rec {
    unwrapped = prev.callPackage ./nvhpc {
      inherit version url sha256;
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
    url = "https://developer.download.nvidia.com/hpc-sdk/20.9/nvhpc_2020_209_Linux_x86_64_cuda_11.0.tar.gz";
    sha256 ="0n7xdyqzsixsyahk604akn5z5dpyzyw1c6jk7mgiaj0v5rv7v84g";
  };
  nvhpcPackages_21_5 = nvhpcPackages {
    version="21.5";
    url = "https://developer.download.nvidia.com/hpc-sdk/21.5/nvhpc_2021_215_Linux_x86_64_cuda_11.3.tar.gz";
    sha256 ="0bahwqfqz5j93s9gifsbgdbr1wafc6np4hlhrbjvv7q9cbbcs966";
  };
  nvhpcPackages_21_7 = nvhpcPackages {
    version="21.7";
    url = "https://developer.download.nvidia.com/hpc-sdk/21.7/nvhpc_2021_217_Linux_x86_64_cuda_11.4.tar.gz";
    sha256 ="sha256-4gYuC09W9LMe2I0I+MufNxvy8vsMWaBrJHODPHQsi3U=";
  };
}

