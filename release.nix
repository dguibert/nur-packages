{ versions ? import ./versions.nix
, src ? builtins.fetchGit ./.
, nixpkgs ? { outPath = versions.nixpkgs; revCount = 123456; shortRev = "gfedcba"; }
, # The system packages will be built on. See the manual for the
  # subtle division of labor between these two `*System`s and the three
  # `*Platform`s.
  localSystem ? { system = builtins.currentSystem; }

, # These are needed only because nix's `--arg` command-line logic doesn't work
  # with unnamed parameters allowed by ...
  system ? localSystem.system
, platform ? localSystem.platform
, # The system packages will ultimately be run on.
  crossSystem ? localSystem

, # Allow a configuration attribute set to be passed in as an argument.
  config ? import ./config.nix

, # List of overlays layers used to extend Nixpkgs.
  overlays ? []

, # List of overlays to apply to target packages only.
  crossOverlays ? []

, # A function booting the final package set for a specific standard
  # environment. See below for the arguments given to that function, the type of
  # list it returns.
  stdenvStages ? null #import ../stdenv

} @ args:

let pkgs = import nixpkgs {
    inherit localSystem config;
    overlays = with import ./overlays;
    [
      default
      aocc
      flang
      intel-compilers
#      arm
      pgi
      local
    ] ++ overlays;
  };
in {

  ci = (import ./ci.nix { inherit pkgs; }).buildPkgs;

  nix = pkgs.nix;
  #aoccPackages_121 = pkgs.aoccPackages_121;
  #aoccPackages_130 = pkgs.aoccPackages_130;
  #aoccPackages_131 = pkgs.aoccPackages_131;

  #flangPackages_5 = pkgs.flangPackages_5;
  #flangPackages_6 = pkgs.flangPackages_6;
  #flangPackages_7 = pkgs.flangPackages_7;

  #pgiPackages_1810 = pkgs.pgiPackages_1810;

  #intelPackages_2018_3_222 = pkgs.intelPackages_2018_3_222;
  #intelPackages_2018_5_274 = pkgs.intelPackages_2018_5_274;
  #intelPackages_2019_0_117 = pkgs.intelPackages_2019_0_117;
  #intelPackages_2019_1_144 = pkgs.intelPackages_2019_1_144;
  #intelPackages_2019_2_187 = pkgs.intelPackages_2019_2_187;

  #armPackages_190 = pkgs.armPackages_190;

  helloIntel = pkgs.helloIntel;
  miniapp-ping-pongIntel = pkgs.miniapp-ping-pongIntel;
  #jobs = pkgs.jobs;

  nix_binary_tarball = with pkgs; let
    nix_root = pkgs.nix_root or "/nix";
    nix_ = pkgs.nix;
    version = nix_.version;
    installerClosureInfo = closureInfo { rootPaths = [ nix_ cacert ]; };
  in
    runCommand "nix-binary-tarball-${version}"
      { nativeBuildInputs = lib.optional (system != "aarch64-linux") shellcheck;
        meta.description = "Distribution-independent Nix bootstrap binaries for ${system}";
      }
      ''
        tar xf ${nix_.src}
        cp ${installerClosureInfo}/registration $TMPDIR/reginfo
        substitute nix-${version}/scripts/install-nix-from-closure.sh $TMPDIR/install \
          --subst-var-by nix ${nix_} \
          --subst-var-by cacert ${cacert}
        sed -i -e 's@dest="/nix"@dest="${nix_root}"@' $TMPDIR/install

        substitute nix-${version}/scripts/install-darwin-multi-user.sh $TMPDIR/install-darwin-multi-user.sh \
          --subst-var-by nix ${nix_} \
          --subst-var-by cacert ${cacert}
        substitute nix-${version}/scripts/install-systemd-multi-user.sh $TMPDIR/install-systemd-multi-user.sh \
          --subst-var-by nix ${nix_} \
          --subst-var-by cacert ${cacert}
        substitute nix-${version}/scripts/install-multi-user.sh $TMPDIR/install-multi-user \
          --subst-var-by nix ${nix_} \
          --subst-var-by cacert ${cacert}

        if type -p shellcheck; then
          # SC1090: Don't worry about not being able to find
          #         $nix/etc/profile.d/nix.sh
          shellcheck --exclude SC1090 $TMPDIR/install
          shellcheck $TMPDIR/install-darwin-multi-user.sh
          shellcheck $TMPDIR/install-systemd-multi-user.sh

          # SC1091: Don't panic about not being able to source
          #         /etc/profile
          # SC2002: Ignore "useless cat" "error", when loading
          #         .reginfo, as the cat is a much cleaner
          #         implementation, even though it is "useless"
          # SC2116: Allow ROOT_HOME=$(echo ~root) for resolving
          #         root's home directory
	  # SC2034:
          shellcheck --external-sources \
            --exclude SC1091,SC2002,SC2116,SC2034 $TMPDIR/install-multi-user
        fi

        chmod +x $TMPDIR/install
        chmod +x $TMPDIR/install-darwin-multi-user.sh
        chmod +x $TMPDIR/install-systemd-multi-user.sh
        chmod +x $TMPDIR/install-multi-user
        dir=nix-${version}-${system}
        fn=$out/$dir.tar.bz2
        mkdir -p $out/nix-support
        echo "file binary-dist $fn" >> $out/nix-support/hydra-build-products
        tar cvfj $fn \
          --owner=0 --group=0 --mode=u+rw,uga+r \
          --absolute-names \
          --hard-dereference \
          --transform "s,$TMPDIR/install,$dir/install," \
          --transform "s,$TMPDIR/reginfo,$dir/.reginfo," \
          --transform "s,$NIX_STORE,$dir/store,S" \
          $TMPDIR/install $TMPDIR/install-darwin-multi-user.sh \
          $TMPDIR/install-systemd-multi-user.sh \
          $TMPDIR/install-multi-user $TMPDIR/reginfo \
          $(cat ${installerClosureInfo}/store-paths)
      '';

  nix_env = with pkgs; mkEnv { name="nix";
    buildInputs = [
      nix
    ];
    inherit (versions) NIX_PATH;
  };
  cluster_env = with pkgs; mkEnv {
    name = "cluster";
    buildInputs = [
      nix
      gitAndTools.git-annex
      gitAndTools.hub
      gitAndTools.git-crypt
      gitFull #guiSupport is harmless since we also installl xpra
      subversion
      tig
      direnv
      jq
      lsof
      #xpra
      htop
      tree

      # testing (removed 20171122)
      #Mitos
      #MemAxes
      python3

      editorconfig-core-c
    ];
  };

  #hello_opt = pkgs.withOpenMP (pkgs.optimizePackage pkgs.hello);
  #hello_stdopt = pkgs.hello.override { stdenv = pkgs.optimizedStdEnv pkgs.stdenv;};
}
