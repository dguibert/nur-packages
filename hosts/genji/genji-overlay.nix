final: prev: {
  nixStore = "/home_nfs/bguibertd/nix";

  p11-kit = prev.p11-kit.overrideAttrs (attrs: {
    doCheck = false;
  });
  go_bootstrap = prev.go_bootstrap.overrideAttrs (attrs: {
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
  go_1_10 = prev.go_1_10.overrideAttrs (attrs: {
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
  go_1_11 = prev.go_1_11.overrideAttrs (attrs: {
    doCheck = false;
  });
  go_1_13 = prev.go_1_13.overrideAttrs (attrs: {
    doCheck = false;
  });
  libuv = builtins.trace "libuv spartan" prev.libuv.overrideAttrs (attrs: {
    doCheck = false;
  });

  jobs = prev.jobs.override {
    admin_scripts_dir = "/home_nfs/script/admin";
        #scheduler = prev.jobs.scheduler_slurm;
      };
      fetchannex = { file ? builtins.baseNameOf url
      , repo ? "${builtins.getEnv "HOME"}/nur-packages/downloads"
      , name ? builtins.baseNameOf url
      , recursiveHash ? false
      , sha256
      , url
    }: prev.requireFile {
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
  slurm = prev.slurm_17_11_5;

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-self: python-super: {
      pyslurm = python-super.pyslurm_17_11_12.override { slurm=final.slurm; };
    })
  ];

}

