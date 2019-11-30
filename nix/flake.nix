{
  description = "The purely functional package manager";

  edition = 201909;

  inputs.nixpkgs.uri = "nixpkgs/release-19.09";

  outputs = { self, nixpkgs, nix }:

    let
      officialRelease = false;

      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ nix.overlay self.overlay overlays.default ];
        }
      );

      overlays = import ../overlays;

    in {

      # A Nixpkgs overlay that overrides the 'nix'
      overlay = import ./nix-overlay.nix;

      hydraJobs = {

        # Source tarball.
        tarball = nix.hydraJobs.tarball;

        # Binary package for various platforms.
        build = nixpkgs.lib.genAttrs systems (system: nixpkgsFor.${system}.nix);

        # Perl bindings for various platforms.
        perlBindings = nixpkgs.lib.genAttrs systems (system: nixpkgsFor.${system}.nix.perl-bindings);

        # Binary tarball for various platforms, containing a Nix store
        # with the closure of 'nix' package, and the second half of
        # the installation script.
        binaryTarball = nixpkgs.lib.genAttrs systems (system:

          with nixpkgsFor.${system};

          let
            #version = nix.src.version;
            version = nix.hydraJobs.tarball.version;
            nix_ = nixpkgsFor.${system}.nix;
            installerClosureInfo = closureInfo { rootPaths = [ nix_ cacert ]; };
          in

          runCommand "nix-binary-tarball-${version}"
            { #nativeBuildInputs = lib.optional (system != "aarch64-linux") shellcheck;
              meta.description = "Distribution-independent Nix bootstrap binaries for ${system}";
            }
            ''
              set -x
              tar xf ${nix_.src}/tarballs/nix-*.tar.xz
              cp ${installerClosureInfo}/registration $TMPDIR/reginfo
              substitute nix-${version}/scripts/install-nix-from-closure.sh $TMPDIR/install \
                --subst-var-by nix ${nix_} \
                --subst-var-by cacert ${cacert}
              sed -i -e 's@dest="/nix"@dest="${nixStore}"@' $TMPDIR/install

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
                shellcheck --external-sources \
                  --exclude SC1091,SC2002,SC2116 $TMPDIR/install-multi-user
              fi

              chmod +x $TMPDIR/install
              chmod +x $TMPDIR/install-darwin-multi-user.sh
              chmod +x $TMPDIR/install-systemd-multi-user.sh
              chmod +x $TMPDIR/install-multi-user
              dir=nix-${version}-${system}
              fn=$out/$dir.tar.xz
              mkdir -p $out/nix-support
              echo "file binary-dist $fn" >> $out/nix-support/hydra-build-products
              tar cvfJ $fn \
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
            '');

        # The first half of the installation script. This is uploaded
        # to https://nixos.org/nix/install. It downloads the binary
        # tarball for the user's system and calls the second half of the
        # installation script.
        installerScript =
          with nixpkgsFor.x86_64-linux;
          runCommand "installer-script"
            { buildInputs = [ nix ];
            }
            ''
              mkdir -p $out/nix-support

              substitute ${./scripts/install.in} $out/install \
                ${pkgs.lib.concatMapStrings
                  (system: "--replace '@binaryTarball_${system}@' $(nix --experimental-features nix-command hash-file --base16 --type sha256 ${self.hydraJobs.binaryTarball.${system}}/*.tar.xz) ")
                  [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" ]
                } \
                --replace '@nixVersion@' ${nix.src.version}
                --replace 'dest="/nix" 'dest="${nixStore}'

              echo "file installer $out/install" >> $out/nix-support/hydra-build-products
            '';

        # Line coverage analysis.
        coverage =
          with nixpkgsFor.x86_64-linux;
          with commonDeps pkgs;

          releaseTools.coverageAnalysis {
            name = "nix-build";
            src = self.hydraJobs.tarball;

            buildInputs = buildDeps;

            dontInstall = false;

            doInstallCheck = true;

            lcovFilter = [ "*/boost/*" "*-tab.*" ];

            # We call `dot', and even though we just use it to
            # syntax-check generated dot files, it still requires some
            # fonts.  So provide those.
            FONTCONFIG_FILE = texFunctions.fontsConf;
          };

        # System tests.
        tests.remoteBuilds = import ./tests/remote-builds.nix {
          system = "x86_64-linux";
          inherit nixpkgs;
          inherit (self) overlay;
        };

        tests.nix-copy-closure = import ./tests/nix-copy-closure.nix {
          system = "x86_64-linux";
          inherit nixpkgs;
          inherit (self) overlay;
        };

        tests.githubFlakes = (import ./tests/github-flakes.nix rec {
          system = "x86_64-linux";
          inherit nixpkgs;
          inherit (self) overlay;
        });

        tests.setuid = nixpkgs.lib.genAttrs
          ["i686-linux" "x86_64-linux"]
          (system:
            import ./tests/setuid.nix rec {
              inherit nixpkgs system;
              inherit (self) overlay;
            });

        # Test whether the binary tarball works in an Ubuntu system.
        tests.binaryTarball =
          with nixpkgsFor.x86_64-linux;
          vmTools.runInLinuxImage (runCommand "nix-binary-tarball-test"
            { diskImage = vmTools.diskImages.ubuntu1204x86_64;
            }
            ''
              set -x
              useradd -m alice
              su - alice -c 'tar xf ${self.hydraJobs.binaryTarball.x86_64-linux}/*.tar.*'
              mkdir /dest-nix
              mount -o bind /dest-nix /nix # Provide a writable /nix.
              chown alice /nix
              su - alice -c '_NIX_INSTALLER_TEST=1 ./nix-*/install'
              su - alice -c 'nix-store --verify'
              su - alice -c 'PAGER= nix-store -qR ${self.hydraJobs.build.x86_64-linux}'

              # Check whether 'nix upgrade-nix' works.
              cat > /tmp/paths.nix <<EOF
              {
                x86_64-linux = "${self.hydraJobs.build.x86_64-linux}";
              }
              EOF
              su - alice -c 'nix --experimental-features nix-command upgrade-nix -vvv --nix-store-paths-url file:///tmp/paths.nix'
              (! [ -L /home/alice/.profile-1-link ])
              su - alice -c 'PAGER= nix-store -qR ${self.hydraJobs.build.x86_64-linux}'

              mkdir -p $out/nix-support
              touch $out/nix-support/hydra-build-products
              umount /nix
            '');

        /*
        # Check whether we can still evaluate all of Nixpkgs.
        tests.evalNixpkgs =
          import (nixpkgs + "/pkgs/top-level/make-tarball.nix") {
            # FIXME: fix pkgs/top-level/make-tarball.nix in NixOS to not require a revCount.
            inherit nixpkgs;
            pkgs = nixpkgsFor.x86_64-linux;
            officialRelease = false;
          };

        # Check whether we can still evaluate NixOS.
        tests.evalNixOS =
          with nixpkgsFor.x86_64-linux;
          runCommand "eval-nixos" { buildInputs = [ nix ]; }
            ''
              export NIX_STATE_DIR=$TMPDIR

              nix-instantiate ${nixpkgs}/nixos/release-combined.nix -A tested --dry-run \
                --arg nixpkgs '{ outPath = ${nixpkgs}; revCount = 123; shortRev = "abcdefgh"; }'

              touch $out
            '';
        */

        # Aggregate job containing the release-critical jobs.
        release =
          with self.hydraJobs;
          nixpkgsFor.x86_64-linux.releaseTools.aggregate {
            name = "nix-${tarball.version}";
            meta.description = "Release-critical builds";
            constituents =
              [ tarball
                build.i686-linux
                build.x86_64-darwin
                build.x86_64-linux
                build.aarch64-linux
                binaryTarball.i686-linux
                binaryTarball.x86_64-darwin
                binaryTarball.x86_64-linux
                binaryTarball.aarch64-linux
                tests.remoteBuilds
                tests.nix-copy-closure
                tests.binaryTarball
                #tests.evalNixpkgs
                #tests.evalNixOS
                installerScript
              ];
          };

      };

      checks = forAllSystems (system: {
        binaryTarball = self.hydraJobs.binaryTarball.${system};
        perlBindings = self.hydraJobs.perlBindings.${system};
      });

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) nix;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.nix);

      devShell.x86_64-linux = with nixpkgsFor.x86_64-linux; mkEnv rec {
        name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
        buildInputs = [ nixpkgsFor.x86_64-linux.nix jq ];
        shellHook = ''
          export XDG_CACHE_HOME=$HOME/.cache/${name}
          unset NIX_STORE
        '';
      };

      #devShell = forAllSystems (system:
      #  with nixpkgsFor.${system};
      #  with commonDeps pkgs;

      #  stdenv.mkDerivation {
      #    name = "nix";

      #    buildInputs = buildDeps ++ tarballDeps ++ perlDeps;

      #    inherit configureFlags;

      #    enableParallelBuilding = true;

      #    installFlags = "sysconfdir=$(out)/etc";

      #    shellHook =
      #      ''
      #        export prefix=$(pwd)/inst
      #        configureFlags+=" --prefix=$prefix"
      #        PKG_CONFIG_PATH=$prefix/lib/pkgconfig:$PKG_CONFIG_PATH
      #        PATH=$prefix/bin:$PATH
      #        unset PYTHONPATH
      #      '';
      #  });

  };
}
