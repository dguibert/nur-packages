final: prev: {
  lib = prev.lib.extend(final: prev: {
    fetchers = import ./lib/fetchers.nix prev.lib;
  });

  # fix infinite recursion
  # `fetchurl' downloads a file from the network.
  fetchurl = if stdenv.buildPlatform != stdenv.hostPlatform
    then buildPackages.fetchurl # No need to do special overrides twice,
    else makeOverridable (import ../build-support/fetchurl) {
      inherit lib stdenvNoCC buildPackages;
      inherit cacert;
      curl = buildPackages.curlMinimal.override (old: rec {
        # break dependency cycles
        fetchurl = stdenv.fetchurlBoot;
        zlib = buildPackages.zlib.override { fetchurl = stdenv.fetchurlBoot; };
        pkg-config = buildPackages.pkg-config.override (old: {
          pkg-config = old.pkg-config.override {
            fetchurl = stdenv.fetchurlBoot;
          };
        });
        perl = buildPackages.perl.override { fetchurl = stdenv.fetchurlBoot; inherit zlib; };
        openssl = buildPackages.openssl.override {
          fetchurl = stdenv.fetchurlBoot;
          buildPackages = {
            coreutils = (buildPackages.coreutils.override rec {
              fetchurl = stdenv.fetchurlBoot;
              inherit perl;
              xz = buildPackages.xz.override { fetchurl = stdenv.fetchurlBoot; };
              gmp = null;
              aclSupport = false;
              attrSupport = false;
              autoreconfHook = null;
              texinfo = null;
            }).overrideAttrs (_: {
              preBuild = "touch Makefile.in"; # avoid automake
            });
            inherit perl;
          };
          inherit perl;
        };
        libssh2 = buildPackages.libssh2.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit zlib openssl;
        };
        # On darwin, libkrb5 needs bootstrap_cmds which would require
        # converting many packages to fetchurl_boot to avoid evaluation cycles.
        # So turn gssSupport off there, and on Windows.
        # On other platforms, keep the previous value.
        gssSupport =
          if stdenv.isDarwin || stdenv.hostPlatform.isWindows
            then false
            else old.gssSupport or true; # `? true` is the default
        libkrb5 = buildPackages.libkrb5.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit pkg-config perl openssl;
          keyutils = buildPackages.keyutils.override { fetchurl = stdenv.fetchurlBoot; };
        };
        nghttp2 = buildPackages.nghttp2.override {
          fetchurl = stdenv.fetchurlBoot;
          inherit pkg-config;
          enableApp = false; # curl just needs libnghttp2
          enableTests = false; # avoids bringing `cunit` and `tzdata` into scope
        };
      });
    };

}
