final: prev: with final; let
    tryUpstream = drv: attrs: (drv.overrideAttrs attrs).overrideAttrs (o: {
      isBroken = isBroken drv;
    });
    #if (builtins.tryEval (isBroken drv)).success
    #then (isBroken drv) # should fail and use our override
    #else drv.overrideAttrs attrs;
in {
  nixStore = "/ccc/scratch/cont003/bull/guibertd/nix";
  nix = prev.nix.overrideAttrs (o: {
    patches = (o.patches or []) ++ [
      ../../pkgs/nix-dont-remove-lustre-xattr.patch
      ../../pkgs/nix-unshare.patch
    ];
    LD_LIBRARY_PATH = "${prev.sssd}/lib";
    #doInstallCheck = false; # error: cannot figure out user name
  });
  #stdenv = prev.stdenv // {
  #  mkDerivation = args: let
  #      name = args.pname or args.name;
  #    in prev.stdenv.mkDerivation (args // {
  #    LD_LIBRARY_PATH = "${prev.sssd}/lib"; # infinite recursion
  #  });
  #};
  getpwuid = stdenv.mkDerivation rec {
    name = "getpwuid-0.0";
    LD_LIBRARY_PATH = "${sssd}/lib";
    src = writeText "getpwuid.py" ''
      import os
      import pwd

      results = pwd.getpwuid( os.getuid() )
      print( results )
    '';
    phases = [ "buildPhase" ];
    buildPhase = ''
      ${python}/bin/python ${src} | tee $out
    '';
  };
  #aws-sdk-cpp = tryUpstream prev.aws-sdk-cpp
  #  (attrs: {
  #        doCheck = false;
  #  });

  #p11-kit = tryUpstream prev.p11-kit (attrs: {
  #  enableParallelBuilding = false;
  #  doCheck = false;
  #  doInstallCheck=false;
  #});
  #boehmgc = tryUpstream prev.boehmgc (attrs: {
  #  doCheck = false;
  #  doInstallCheck=false;
  #});
  #git = tryUpstream prev.git (attrs: {
  #  doCheck = false;
  #  doInstallCheck=false;
  #});
  #libuv = tryUpstream prev.libuv (attrs: {
  #  doCheck = false;
  #});
  slurm = prev.slurm_17_11_5;

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-self: python-super: {
      hypothesis = python-super.hypothesis.overrideAttrs (attrs: {
        doCheck = false;
      	doInstallCheck=false;
      });
      pyslurm = python-super.pyslurm_17_11_12.override { slurm=final.slurm; };
    })
  ];



  jobs = prev.jobs.override {
    admin_scripts_dir = null; #"/home_nfs/script/admin";
    scheduler = prev.jobs.scheduler_slurm;

    default_sbatch = {
      job-name="job";
      nodes="1";
      account = "cellvt@genci";
      partition=prev.jobs.scheduler_slurm.partitions.tx2.name;
      time="00:30:00";
      exclusive=true;
      verbose=true;
      no-requeue=true;
      #ntasks-per-node="8";
      #cpus-per-task="5";
      #threads-per-core="1";
    };
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

  patchelf = prev.patchelf.overrideAttrs ( attrs: {
    configureFlags = "--with-page-size=65536";
  });

}
