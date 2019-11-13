
{
  epoch = 201909;

  description = "A flake for building my NUR packages";

  inputs = {
    nixpkgs.uri = "github:dguibert/nixpkgs/pu";
  };

  outputs = { self, nixpkgs, nix }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      #localSystem = { system = "x86_64-linux"; };# FIXME hard coded for now
      overlays =  [
        self.overlay
        nix.overlay
      ];
      config.allowUnfree = true;
    };

  in rec {

      packages.x86_64-linux = {
        inherit (pkgs) hello nix
        openmpi
        ;
      };

      devShell.x86_64-linux = with pkgs; mkEnv {
        name = "nix";
        buildInputs = [ nix jq ];
      };

      ## - TODO: NixOS-related outputs such as nixosModules and nixosSystems.
      nixosModules = {
        qemu-user = import ./modules/qemu-user.nix;
      };

      lib = import ./lib { inherit pkgs; };

      overlay = overlays.packages;

      overlays = {
        local = self: super: if (builtins.pathExists ./overlays/local.nix) then (import (./overlays/local.nix)) self super else {};

        aocc = import ./overlays/aocc-overlay;
        flang = import ./overlays/flang-overlay;
        qemu-user = import ./overlays/qemu-user.nix;
        intel-compilers = import ./overlays/intel-compilers-overlay;
        arm = import ./overlays/arm-overlay;
        pgi = import ./overlays/pgi-overlay;

        nix-home-nfs-bguibertd          = import ./overlays/nix-store-overlay.nix "/home_nfs/bguibertd/nix";
        nix-home-nfs-robin-ib-bguibertd = import ./overlays/nix-store-overlay.nix "/home_nfs_robin_ib/bguibertd/nix";
        nix-scratch-gpfs-bguibertd      = import ./overlays/nix-store-overlay.nix "/scratch_gpfs/bguibertd/nix";
        #nix-ccc-guibertd                = import ./overlays/nix-store-overlay.nix "/ccc/dsku/nfs-server/user/cont003/bull/guibertd/nix";
        nix-ccc-guibertd                = import ./overlays/nix-store-overlay.nix "/ccc/scratch/cont003/bull/guibertd/nix";

        packages = final: prev: {
          adapters = import ./pkgs/stdenv/adapters.nix prev;
          inherit (final.adapters) optimizePackage
                             withOpenMP
                             optimizedStdEnv
                             customFlags
                             extraNativeCflags
                             customFlagsWithinStdEnv;

          example-package = final.callPackage ./pkgs/example-package { };
          # some-qt5-package = prev.libsForQt5.callPackage ./pkgs/some-qt5-package { };
          # ...
          dyninst = final.callPackage ./pkgs/dyninst { };
          palabos = final.callPackage ./pkgs/palabos { };
          otf2 = final.callPackage ./pkgs/otf2 { };

          score-p = final.callPackage ./pkgs/score-p {
            inherit (final) otf2;
            inherit (final) cubew;
            inherit (final) cubelib;
          };
          caliper = final.callPackage ./pkgs/caliper {
            inherit (final) dyninst;
          };

          compilers_line = stdenv: mpi: let
            compiler_id = if (stdenv.cc.isIntel or false) then "intel" else "gnu";
            mpi_id = if (mpi.isIntel or false) then "intel" else
                     if (mpi != null) then "openmpi" else "none";
          in {
              intel = {
                intel = "CC=mpiicc CXX=mpiicpc F77=mpiifort FC=mpiifort";
                openmpi = "CC=mpicc CXX=mpicxx F77=mpif90 FC=mpif90";
                none = "CC=icc CXX=icpc F77=ifort FC=ifort";
              };
              gnu = {
                openmpi = "CC=${mpi}/bin/mpicc";
                none = "";
              };
            }."${compiler_id}"."${mpi_id}";

          cubew = final.callPackage ./pkgs/cubew { };
          cubelib = final.callPackage ./pkgs/cubelib { };
          cubegui = final.callPackage ./pkgs/cubegui { inherit (final) cubelib; };
          dwm = prev.dwm.override {patches = [
            ./pkgs/dwm/0001-dwm-pertag-20170513-ceac8c9.patch
            ./pkgs/dwm/0002-dwm-systray-20180314-3bd8466.diff.patch
            ./pkgs/dwm/0003-config.h-azerty.patch
            ./pkgs/dwm/0004-config.h-audio-controls.patch
            ./pkgs/dwm/0005-light-solarized-theme.patch
            ./pkgs/dwm/0006-config-support-shortcuts-for-vbox-inside-windows.patch
            ./pkgs/dwm/0007-xpra-as-float.patch
            ./pkgs/dwm/0008-qtpass-as-float.patch
            ./pkgs/dwm/0009-pineentry-as-float.patch
          ];};

          fetchannex = final.callPackage ./pkgs/build-support/fetchannex { git-annex = prev.gitAndTools.git-annex; };
          # throw "use gitAndTools.hub instead"
          gitAndTools = (removeAttrs prev.gitAndTools ["hubUnstable"]) // {
            git-credential-password-store = final.callPackage ./pkgs/git-credential-password-store { };
            git-crypt = prev.gitAndTools.git-crypt.overrideAttrs (attrs: {
              # https://github.com/AGWA/git-crypt/issues/105
              patches = (attrs.patches or []) ++ [ ./pkgs/git-crypt-support-worktree-simple-version-patch.txt ];
            });
          };

          jobs = final.callPackage ./pkgs/jobs {
            inherit (final) stream;
            admin_scripts_dir = "";
          };

          hpcg = final.callPackage ./pkgs/hpcg { };
          inherit (final.callPackage ./pkgs/hpl {
            inherit (final) fetchannex;
            inherit (final) nix-patchtools;
          })
            hpl_netlib_2_3
            hpl_mkl_netlib_2_3
            hpl_cuda_ompi_volta_pascal_kepler_3_14_19
          ;

          lmod = final.callPackage ./pkgs/lmod {
              inherit (prev.luaPackages) luafilesystem;
              inherit (final) luaposix;
          };
          luaposix = final.callPackage ./pkgs/luaposix { };

          lo2s = final.callPackage ./pkgs/lo2s { inherit (final) otf2; };
          lulesh = final.callPackage ./pkgs/lulesh { };

          gnumake_slurm = prev.gnumake.overrideAttrs (attrs: {
            patches = (attrs.patches or []) ++ [
               ./pkgs/make/make-4.2.slurm.patch
               #(pkgs.fetchpatch {
               #   url = "https://raw.githubusercontent.com/SchedMD/slurm/master/contribs/make-4.0.slurm.patch";
               #   sha256 = "1rnwcw6xniwq6d0qpbz1b15bzmkl6r9zj20m6jnivif8qd7gkjqf";
               #   stripLen = 1;
               #})
            ];
          });

          hdf5 = final.callPackage ./pkgs/hdf5 {
            gfortran = null;
            szip = null;
            mpi = null;
          };
          hpcbind = final.callPackage ./pkgs/hpcbind { };

          mkEnv = { name ? "env"
                  , buildInputs ? []
                  , ...
                }@args: let name_=name;
                            args_ = builtins.removeAttrs args [ "name" "buildInputs" "shellHook" ];
                in prev.stdenv.mkDerivation (rec {
            name = "${name_}-env";
            phases = [ "buildPhase" ];
            postBuild = "ln -s ${env} $out";
            env = prev.buildEnv { name = name; paths = buildInputs; ignoreCollisions = true; };
            inherit buildInputs;
            shellHook = ''
              export ENVRC=${name_}
              source ~/.bashrc
            '' + (args.shellHook or "");
          } // args_);

          modulefile = final.callPackage ./pkgs/gen-modulefile { };

          must = final.callPackage ./pkgs/must { inherit (final) dyninst; };
          muster = final.callPackage ./pkgs/muster { };
          nemo_36 = final.callPackage ./pkgs/nemo/3.6.nix { xios = final.xios_10; };
          nemo = final.callPackage ./pkgs/nemo { inherit (final) xios; };

          netcdf = final.callPackage ./pkgs/netcdf { inherit (final) compilers_line; };

          nix-patchtools = final.callPackage ./pkgs/nix-patchtools { };

          inherit (final.callPackage ./pkgs/openmpi { enableSlurm=true; inherit lib; openmpi=prev.openmpi; })
            openmpi
            openmpi_4_0_2
          ;

          osu-micro-benchmarks = final.callPackage ./pkgs/osu-micro-benchmarks { };

          # https://github.com/NixOS/nixpkgs/issues/44426
          python27 = prev.python27.override { packageOverrides = final.pythonOverrides; };
          python35 = prev.python35.override { packageOverrides = final.pythonOverrides; };
          python36 = prev.python36.override { packageOverrides = final.pythonOverrides; };
          python37 = prev.python37.override { packageOverrides = final.pythonOverrides; };
          python38 = prev.python38.override { packageOverrides = final.pythonOverrides; };

          pythonOverrides = python-self: python-super: with python-self; {
            pyslurm = lib.upgradeOverride python-super.pyslurm (oldAttrs: rec {
              name = "${oldAttrs.pname}-${version}";
              version = "19-05-0";
            });

            pyslurm_17_02_0 = (python-super.pyslurm.override { slurm=slurm_17_02_11; }).overrideAttrs (oldAttrs: rec {
              name = "${oldAttrs.pname}-${version}";
              version = "17.02.0";

              patches = [];

              preConfigure = ''
                sed -i -e 's@__max_slurm_hex_version__ = "0x11020a"@__max_slurm_hex_version__ = "0x11020b"@' setup.py
              '';

              src = prev.fetchFromGitHub {
                repo = "pyslurm";
                owner = "PySlurm";
                # The release tags use - instead of .
                rev = "refs/heads/17.02.0";
                sha256 = "sha256:1b5xaq0w4rkax8y7rnw35fapxwn739i21dgb9609hg01z9b6n1ka";
              };

            });
            pyslurm_17_11_12 = (python-super.pyslurm.override { slurm=slurm_17_11_9_1;}).overrideAttrs (oldAttrs: rec {
              name = "${oldAttrs.pname}-${version}";
              version = "17.11.12";

              patches = [];

              src = super.fetchFromGitHub {
                repo = "pyslurm";
                owner = "PySlurm";
                # The release tags use - instead of .
                rev = "${builtins.replaceStrings ["."] ["-"] version}";
                sha256 = "01xdx2v3w8i3bilyfkk50f786fq60938ikqp2ls2kf3j218xyxmz";
              };

            });
            mpi4py = builtins.trace "mpi4py without check" python-super.mpi4py.overrideAttrs (oldAttrs: {
              doCheck = false;
            });
          };

          ravel = final.callPackage ./pkgs/ravel {
            inherit (final) otf2;
            inherit (final) muster;
          };
          inherit (final.callPackage ./pkgs/slurm { gtk2 = null; inherit lib; slurm=prev.slurm; })
            slurm_17_02_11
            slurm_17_11_5
            slurm_17_11_9_1
            slurm_18_08_5
            slurm_19_05_3_2
            slurm
          ;
          st = prev.st.override {patches = [
            ./pkgs/st/0001-theme-from-base16-c_header.patch
            #./pkgs/st/0002-Update-base-patch-to-0.8.1.patch
            ./pkgs/st/0003-Show-bold-not-as-bright.patch
            (prev.fetchpatch { url="https://st.suckless.org/patches/clipboard/st-clipboard-20180309-c5ba9c0.diff"; sha256="sha256:1gsqgasc5spklrk7575m7jlxcii072wf03qn9znqwh1ibsy9lnr2"; })
          ];};
          xios_10 = final.callPackage ./pkgs/xios/1.0.nix { };
          xios = final.callPackage ./pkgs/xios { };

          # miniapps
          miniapp-ping-pong = final.callPackage ./pkgs/miniapp-ping-pong {};
          stream = final.callPackage ./pkgs/stream { };
          test-dgemm = final.callPackage ./pkgs/test-dgemm { };

        };
      };
    };
}
