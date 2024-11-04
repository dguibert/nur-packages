final: prev: let
  wrapCCWith = with prev;
    {
      cc,
      # This should be the only bintools runtime dep with this sort of logic. The
      # Others should instead delegate to the next stage's choice with
      # `targetPackages.stdenv.cc.bintools`. This one is different just to
      # provide the default choice, avoiding infinite recursion.
      bintools ?
        if targetPlatform.isDarwin
        then darwin.binutils
        else binutils,
      libc ? bintools.libc,
      ...
    } @ extraArgs:
      callPackage ../flang-overlay/build-support/cc-wrapper (let
        self =
          {
            nativeTools = targetPlatform == hostPlatform && stdenv.cc.nativeTools or false;
            nativeLibc = targetPlatform == hostPlatform && stdenv.cc.nativeLibc or false;
            nativePrefix = stdenv.cc.nativePrefix or "";
            noLibc = !self.nativeLibc && (self.libc == null);

            isGNU = cc.isGNU or false;
            isClang = cc.isClang or false;

            inherit cc bintools libc;
          }
          // extraArgs;
      in
        self);

  aoccPackages = {
    version,
    sha256,
    release_version,
    llvmPackages ? null,
    gcc ? llvmPackages.tools.clang-unwrapped.gcc,
    libcxx ? null,
    bintools ? null,
  }: let
    mkExtraBuildCommands = cc: flang: ''
      ${prev.lib.optionalString (flang != null) "echo \"-I${flang}/include -L${flang}/lib -Wl,-rpath ${flang}/lib -B${flang}/bin\" >> $out/nix-support/cc-cflags"}
      rsrc="$out/resource-root"
      mkdir "$rsrc"

      if test ! -e ${cc}/lib/clang/${release_version}; then
        echo "error: ${cc}/lib/clang/${release_version} does not exists"
        ls ${cc}/lib/clang/
        exit 1
      fi

      ln -s "${cc}/lib/clang/${release_version}/include" "$rsrc"
      mkdir $rsrc/lib
      ln -s "${cc}/lib/*" "$rsrc/lib/"
      ln -s "${cc}/lib/clang/${release_version}/lib/linux" "$rsrc/lib/linux"
      echo "-rtlib=compiler-rt -Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
      echo "-B${llvmPackages.compiler-rt}/lib" >> $out/nix-support/cc-cflags
      echo "--unwindlib=libunwind" >> $out/nix-support/cc-cflags
      echo "-Wl,-rpath ${llvmPackages.libunwind}/lib" >> $out/nix-support/cc-cflags

      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
    '';
  in rec {
    unwrapped = prev.callPackage ./aocc {
      inherit version sha256;
    };
    aocc = wrapCCWith rec {
      cc = unwrapped;
      extraPackages = [
        #llvmPackages.libraries.libcxxabi
        llvmPackages.libraries.compiler-rt
        llvmPackages.libraries.libunwind
      ];
      extraBuildCommands = mkExtraBuildCommands cc cc;
      inherit libcxx bintools;
    };
    stdenv = prev.overrideCC prev.stdenv aocc;
  };
in {
  # https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/aocc/package.py
  aoccPackages_320 = aoccPackages {
    release_version = "13.0.0";
    llvmPackages = prev.llvmPackages_13;
    gcc = final.gcc10.cc;
    version = "3.2.0";
    sha256 = "8493525b3df77f48ee16f3395a68ad4c42e18233a44b4d9282b25dbb95b113ec";
    libcxx = prev.llvmPackages_13.libcxxClang;
    bintools = prev.llvmPackages_13.bintools;
  };
  aoccPackages_500 = aoccPackages {
    release_version = "17";
    llvmPackages = prev.llvmPackages_17;
    gcc = final.gcc10.cc;
    version = "5.0.0";
    sha256 = "1ahd723fqab86zm0f7kz7w8nqc3vgbd0mhb9x7k9v7km5hnsqvwn";
    libcxx = prev.llvmPackages_17.libcxxClang;
    bintools = prev.llvmPackages_17.bintools;
  };
}
