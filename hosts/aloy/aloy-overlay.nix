final: prev:  with final; let
    tryUpstream = drv: attrs: (drv.overrideAttrs attrs).overrideAttrs (o: {
      isBroken = isBroken drv;
    });
    #if (builtins.tryEval (isBroken drv)).success
    #then (isBroken drv) # should fail and use our override
    #else drv.overrideAttrs attrs;
in {
  nixStore = "/home_nfs/bguibertd/nix";

  p11-kit = tryUpstream prev.p11-kit (attrs: {
    enableParallelBuilding = false;
    doCheck = false;
    doInstallCheck=false;
  });
#  boehmgc = tryUpstream prev.boehmgc (attrs: {
#    doCheck = false;
#    doInstallCheck=false;
#  });
  jobs = prev.jobs.override {
    admin_scripts_dir = "/home_nfs/script/admin";
    #scheduler = prev.jobs.scheduler_slurm;
  };
  mkJob = prev.jobs.mkJob.override {
    jobImpl = final.jobs.sbatchJob;
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
  slurm = prev.slurm_17_02_11;

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-final: python-prev: {
      pyslurm = python-prev.pyslurm_17_11_12.override { slurm=final.slurm; };
    })
  ];
}
