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
      callPackage ../flang-overlay/build-support/cc-wrapper (let self = {
    nativeTools = targetPlatform == hostPlatform && stdenv.cc.nativeTools or false;
    nativeLibc = targetPlatform == hostPlatform && stdenv.cc.nativeLibc or false;
    nativePrefix = stdenv.cc.nativePrefix or "";
    noLibc = !self.nativeLibc && (self.libc == null);

    isGNU = cc.isGNU or false;
    isClang = cc.isClang or false;

    inherit cc bintools libc;
  } // extraArgs; in self);

  aoccPackages = { version, sha256, release_version
                 , llvmPackages ? null
		 , gcc ? llvmPackages.tools.clang-unwrapped.gcc
	         }: let
    mkExtraBuildCommands = cc: flang: ''
      ${prev.lib.optionalString (flang !=null) "echo \"-I${flang}/include -L${flang}/lib -Wl,-rpath ${flang}/lib -B${flang}/bin\" >> $out/nix-support/cc-cflags"}
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/${release_version}/include" "$rsrc"
      ln -s "${cc}/lib" "$rsrc/lib"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
    '' + prev.lib.optionalString prev.stdenv.targetPlatform.isLinux ''
      echo "--gcc-toolchain=${gcc}" >> $out/nix-support/cc-cflags
    '';
  in rec {
    unwrapped = prev.callPackage ./aocc {
      inherit version sha256;
    };
    aocc = wrapCCWith rec {
      cc = unwrapped;
      extraPackages = [
	#llvmPackages.libraries.compiler-rt
      ];
      extraBuildCommands = mkExtraBuildCommands cc cc;
    };
    stdenv = prev.overrideCC prev.stdenv aocc;
  };

in
{
  aoccPackages_121 = aoccPackages {
    release_version = "6.0.0";
    llvmPackages = prev.llvmPackages_6;
    version="1.2.1";
    sha256 ="008w6algs72d3klkdpaj95nz6ax1y2dyp4zflv4xpz3ybbc7whar";
  };

  aoccPackages_130 = aoccPackages {
    release_version = "7.0.0";
    llvmPackages = prev.llvmPackages_7;
    version="1.3.0";
    sha256 ="0zi1j23h9gmw62d883m3yfa9hjkpznky5jlc4w2d34mmj4njwmms";
  };

  aoccPackages_131 = aoccPackages {
    release_version = "9.0.0";
    llvmPackages = prev.llvmPackages_9;
    version="1.3.1";
    sha256 ="1nbzbw1jal4b8nzk0hj3zwalxna34f50j1v5l2aj2yp6aijla20s";
  };

  aoccPackages_200 = aoccPackages {
    release_version = "9.0.0";
    llvmPackages = prev.llvmPackages_9;
    version="2.0.0";
    sha256 ="15syknz09hjdp4qnrzrbizfxxcvsg55i7417wvb417x3cis73z19";
  };

  aoccPackages_210 = aoccPackages {
    release_version = "9.0.0";
    gcc = final.gcc9.cc;
    version="2.1.0";
    sha256 ="084xgg6xnrjrzl1iyqyrb51f7x2jnmpzdd39ad81dn10db99b405";
  };
}
