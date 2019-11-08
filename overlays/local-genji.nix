self: super:
let
  overlay = (super.lib.composeOverlays [
   (self: super: {
     _toolchain = builtins.trace "toolchain: ${super._toolchain}.genji" ("${super._toolchain}.genji");
     p11-kit = super.p11-kit.overrideAttrs (attrs: {
       doCheck = false;
     });
     go_bootstrap = super.go_bootstrap.overrideAttrs (attrs: {
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
     go_1_13 = super.go_1_13.overrideAttrs (attrs: {
       doCheck = false;
     });
     libuv = super.libuv.overrideAttrs (attrs: {
       doCheck = false;
     });
     slurm = super.slurm_17_11_5;

     pythonOverrides = super.lib.composeOverlays (python-self: python-super: {
       pyslurm = python-super.pyslurm_17_11_12.override { slurm=self.slurm; };
     }) (super.pythonOverrides or (_:_: {}));

     jobs = super.jobs.override {
       admin_scripts_dir = "/home_nfs/script/admin";
       #scheduler = super.jobs.scheduler_slurm;
     };
     fetchannex = { file ? builtins.baseNameOf url
                  , repo ? "${builtins.getEnv "HOME"}/nur-packages/downloads"
                  , name ? builtins.baseNameOf url
                  , recursiveHash ? false
                  , sha256
                  , url
     }: super.requireFile {
       inherit name sha256 url;
       hashMode = if recursiveHash then "recursive" else "flat";
       message = ''
        Unfortunately, we cannot download file ${name} automatically.
        either:
          - go to ${url} to download it yourself
          - get it to the git annexed repo ${repo}

        and add it to the Nix store
          nix-store --add-fixed sha256 ${repo}/${name}

       '';
     };
  })
   (import ./default.nix).nix-home-nfs-robin-ib-bguibertd
  ]);
in overlay self super
