self: super:
let
  overlay = (super.lib.composeOverlays [
   (import ./default.nix).nix-ccc-guibertd
   (self: super: {
     _toolchain = builtins.trace "toolchain: ${super._toolchain}.inti" ("${super._toolchain}.inti");
     aws-sdk-cpp = super.aws-sdk-cpp.overrideAttrs (attrs: {
       doCheck = false;
     });
     boehmgc = super.boehmgc.overrideAttrs (attrs: {
       doCheck = false;
     });
     go_1_10 = super.go_1_10.overrideAttrs (attrs: {
       doCheck = false;
       installPhase = ''
         mkdir -p "$out/bin"
         export GOROOT="$(pwd)/"
         export GOBIN="$out/bin"
         export PATH="$GOBIN:$PATH"
         cd ./src
         ./make.bash
       '';
     });
     go_1_11 = super.go_1_11.overrideAttrs (attrs: {
       doCheck = false;
     });
     jemalloc = super.jemalloc.overrideAttrs (attrs: {
       doCheck = false;
     });
     jemalloc450 = super.jemalloc450.overrideAttrs (attrs: {
       doCheck = false;
     });
     libjpeg_turbo = super.libjpeg_turbo.overrideAttrs (attrs: {
       doCheck = false;
     });
     libuv = super.libuv.overrideAttrs (attrs: {
       doCheck = false;
     });
     e2fsprogs = super.e2fsprogs.overrideAttrs (attrs: {
       doCheck = false;
     });
     #slurm = (super.slurm.override { enableX11=false; }).overrideAttrs (attrs: rec {
     #  name = "slurm-${version}";
     #  version = "16.05.11.1";

     #  # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
     #  # because the latter does not keep older releases.
     #  src = super.fetchFromGitHub {
     #    owner = "SchedMD";
     #    repo = "slurm";
     #    # The release tags use - instead of .
     #    rev = "${builtins.replaceStrings ["."] ["-"] name}";
     #    sha256 = "sha256:1l264fc12il7d1c1a8prd20kx68g4brzk3x2c3xsqw0ff1rwlmhh";
     #  };
     #});
     slurm = super.slurm_17_11_5;

     python = super.python.override {
       packageOverrides = python-self: python-super: {
         pyslurm = python-super.pyslurm.overrideAttrs (oldAttrs: rec {
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
       };
     };

     jobs = super.jobs.override {
       admin_scripts_dir = null; #"/home_nfs/script/admin";
       scheduler = super.jobs.scheduler_slurm;

       default_sbatch = {
         job-name="job";
         nodes="1";
         account = "cellvt@genci";
         partition=super.jobs.scheduler_slurm.partitions.tx2.name;
         time="00:30:00";
         exclusive=true;
         verbose=true;
         no-requeue=true;
         #ntasks-per-node="8";
         #cpus-per-task="5";
         #threads-per-core="1";
       };
     };

   })
 ]);
in overlay self super
