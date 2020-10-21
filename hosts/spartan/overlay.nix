final: prev: with final; let
    tryUpstream = drv: attrs: builtins.trace "broken upstream ${drv.name}" (drv.overrideAttrs attrs).overrideAttrs (o: {
      isBroken = isBroken drv;
    });
    #if (builtins.tryEval (isBroken drv)).success
    #then (isBroken drv) # should fail and use our override
    #else drv.overrideAttrs attrs;
in {
  nixStore = builtins.trace "nixStore=/home_nfs/bguibertd/nix" "/home_nfs/bguibertd/nix";

  nix = tryUpstream prev.nix (attrs: {
    doCheck = false;
    doInstallCheck=false;
  });
  #libuv = tryUpstream prev.libuv (attrs: {
  #  doCheck = false;
  #  doInstallCheck=false;
  #});
  #p11-kit = tryUpstream prev.p11-kit (attrs: {
  #  enableParallelBuilding = false;
  #  doCheck = false;
  #  doInstallCheck=false;
  #});
  jobs = prev.jobs._override (self: with self; {
    admin_scripts_dir = "/home_nfs/script/admin";
    #scheduler = prev.jobs.scheduler_slurm;
    defaultJob = sbatchJob;
  });

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
  slurm = final.slurm_19_05_5;

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-self: python-super: {
      pyslurm = python-super.pyslurm_19_05_0.override { slurm=final.slurm_19_05_5; };
    })
  ];
}

