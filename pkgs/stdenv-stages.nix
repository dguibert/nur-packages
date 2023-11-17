nixpkgs: system: let
  lib = nixpkgs.lib;
  pkgs_lib = nixpkgs.pkgs.lib;

  localSystem = lib.systems.elaborate {inherit system;};
  getLibc = stage: stage.${localSystem.libc};

  # This function builds the various standard environments used during
  # the bootstrap.  In all stages, we build an stdenv and the package
  # set that can be built with that stdenv.
  stageFun = prevStage: {
    name,
    overrides ? (self: super: {}),
    extraNativeBuildInputs ? [],
  }: let
    thisStdenv = import "${inputs.nixpkgs}/pkgs/stdenv/generic" {
      name = "${name}-stdenv-linux";
      buildPlatform = localSystem;
      hostPlatform = localSystem;
      targetPlatform = localSystem;
      config = prevStage.config;
      inherit extraNativeBuildInputs;
      preHook = prevStage.stdenv.preHook;
      shell = prevStage.stdenv.shell;
      initialPath = prevStage.stdenv.initialPath;
      fetchurlBoot = prevStage.stdenv.fetchurlBoot;

      cc =
        if prevStage.gcc-unwrapped == null
        then null
        else
          (lib.makeOverridable (import "${inputs.nixpkgs}/pkgs/build-support/cc-wrapper") {
            name = "${name}-gcc-wrapper";
            nativeTools = false;
            nativeLibc = false;
            buildPackages = lib.optionalAttrs (prevStage ? stdenv) {
              inherit (prevStage) stdenv;
            };
            cc = prevStage.gcc-unwrapped;
            bintools = prevStage.binutils;
            isGNU = true;
            libc = getLibc prevStage;
            lib = prevStage.lib;
            inherit (prevStage) coreutils gnugrep;
            stdenvNoCC = prevStage.ccWrapperStdenv;
            fortify-headers = prevStage.fortify-headers;
          })
          .overrideAttrs (a:
            lib.optionalAttrs (prevStage.gcc-unwrapped.passthru.isXgcc or false) {
              # This affects only `xgcc` (the compiler which compiles the final compiler).
              postFixup =
                (a.postFixup or "")
                + ''
                  echo "--sysroot=${lib.getDev (getLibc prevStage)}" >> $out/nix-support/cc-cflags
                '';
            });

      overrides = self: super: (overrides self super) // {fetchurl = thisStdenv.fetchurlBoot;};
    };
  in {
    config = prevStage.config;
    overlays = [];
    stdenv = thisStdenv;
  };

  stdenvStages = args: let
    bootStages = import "${inputs.nixpkgs}/pkgs/stdenv" args;
    splitN = 4;
    initBootStages = pkgs_lib.take splitN bootStages;
    tailBootStage = pkgs_lib.drop (splitN + 1) bootStages;
  in
    builtins.trace "stdenvStages" (initBootStages
      ++ [
        # before stage2
        (prevStage:
          builtins.trace "${prevStage.stdenv.name} -> bootstrap-stage-glibc" stageFun prevStage {
            name = "bootstrap-stage-glibc";
            overrides = self: super: {
              inherit
                (prevStage)
                ccWrapperStdenv
                gettext
                gcc-unwrapped
                coreutils
                gnugrep
                perl
                gnum4
                bison
                texinfo
                which
                ;
              dejagnu = super.dejagnu.overrideAttrs (a: {doCheck = false;});

              # We need libidn2 and its dependency libunistring as glibc dependency.
              # To avoid the cycle, we build against bootstrap libc, nuke references,
              # and use the result as input for our final glibc.  We also pass this pair
              # through, so the final package-set uses exactly the same builds.
              libunistring = super.libunistring.overrideAttrs (attrs: {
                postFixup =
                  attrs.postFixup
                  or ""
                  + ''
                    ${self.nukeReferences}/bin/nuke-refs "$out"/lib/lib*.so.*.*
                  '';
                # Apparently iconv won't work with bootstrap glibc, but it will be used
                # with glibc built later where we keep *this* build of libunistring,
                # so we need to trick it into supporting libiconv.
                env = attrs.env or {} // {am_cv_func_iconv_works = "yes";};
              });
              libidn2 = super.libidn2.overrideAttrs (attrs: {
                postFixup =
                  attrs.postFixup
                  or ""
                  + ''
                    ${self.nukeReferences}/bin/nuke-refs -e '${lib.getLib self.libunistring}' \
                      "$out"/lib/lib*.so.*.*
                  '';
              });
              nss_sss = super.nss_sss.overrideAttrs (attrs: {
                postFixup =
                  attrs.postFixup
                  or ""
                  + ''
                    ${self.nukeReferences}/bin/nuke-refs -e '${lib.getLib self.libunistring}' \
                        "$out"/lib/lib*.so.*.*
                  '';
              });

              # This also contains the full, dynamically linked, final Glibc.
              binutils = prevStage.binutils.override {
                # Rewrap the binutils with the new glibc, so both the next
                # stage's wrappers use it.
                libc = getLibc self;

                # Unfortunately, when building gcc in the next stage, its LTO plugin
                # would use the final libc but `ld` would use the bootstrap one,
                # and that can fail to load.  Therefore we upgrade `ld` to use newer libc;
                # apparently the interpreter needs to match libc, too.
                bintools = self.stdenvNoCC.mkDerivation {
                  pname = prevStage.bintools.bintools.pname + "-patchelfed-ld";
                  inherit (prevStage.bintools.bintools) version;
                  passthru = {inherit (prevStage.bintools.passthru) isFromBootstrapFiles;};
                  enableParallelBuilding = true;
                  dontUnpack = true;
                  dontBuild = true;
                  strictDeps = true;
                  # We wouldn't need to *copy* all, but it's easier and the result is temporary anyway.
                  installPhase = ''
                    mkdir -p "$out"/bin
                    cp -a '${prevStage.bintools.bintools}'/bin/* "$out"/bin/
                    chmod +w "$out"/bin/ld.bfd
                    patchelf --set-interpreter '${getLibc self}'/lib/ld*.so.? \
                      --set-rpath "${getLibc self}/lib:$(patchelf --print-rpath "$out"/bin/ld.bfd)" \
                      "$out"/bin/ld.bfd
                  '';
                };
              };

              # TODO(amjoseph): It is not yet entirely clear why this is necessary.
              # Something strange is going on with xgcc and libstdc++ on pkgsMusl.
              patchelf = super.patchelf.overrideAttrs (previousAttrs:
                lib.optionalAttrs super.stdenv.hostPlatform.isMusl {
                  NIX_CFLAGS_COMPILE = (previousAttrs.NIX_CFLAGS_COMPILE or "") + " -static-libstdc++";
                });
              glibc = builtins.trace "version: ${super.glibc.version}" super.glibc.overrideAttrs (attrs: {
                postPatch =
                  (attrs.postPatch or "")
                  + ''
                    sed -i -e 's@_PATH_VARDB.*@_PATH_VARDB "/var/lib/misc"@' sysdeps/unix/sysv/linux/paths.h
                    sed -i -e 's@_PATH_VARDB.*@_PATH_VARDB "/var/lib/misc"@' sysdeps/generic/paths.h
                  '';
                postInstall =
                  attrs.postInstall
                  + ''
                    ln -vs ${pkgs.nss_sss}/lib/*.so.* $out/lib
                  '';
              });
            };

            # `gettext` comes with obsolete config.sub/config.guess that don't recognize LoongArch64.
            # `libtool` comes with obsolete config.sub/config.guess that don't recognize Risc-V.
            extraNativeBuildInputs = [prevStage.updateAutotoolsGnuConfigScriptsHook];
          })
      ]
      ++ tailBootStage);
in
  bootStages
