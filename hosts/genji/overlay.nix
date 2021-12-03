final: prev: with final; let
    tryUpstream = drv: attrs: builtins.trace "broken upstream ${drv.name}" (drv.overrideAttrs attrs).overrideAttrs (o: {
      isBroken = isBroken drv;
    });
    #if (builtins.tryEval (isBroken drv)).success
    #then (isBroken drv) # should fail and use our override
    #else drv.overrideAttrs attrs;
in {
  #nixStore = builtins.trace "nixStore=/home_nfs_robin_ib/bguibertd/nix" "/home_nfs_robin_ib/bguibertd/nix";
  nixStore = builtins.trace "nixStore=/home_nfs/bguibertd/nix" "/home_nfs/bguibertd/nix";

  nix_2_3 = tryUpstream prev.nix_2_3 (o: {
    doCheck = false;
    doInstallCheck=false;
  });
  nixStable = tryUpstream prev.nixStable (o: {
    doCheck = false;
    doInstallCheck=false;
  });
  nix = /*tryUpstream*/ prev.nix.overrideAttrs (o: {
    doCheck = false;
    doInstallCheck=false;
    patches = (o.patches or []) ++ [
      ../../pkgs/nix-dont-remove-lustre-xattr.patch
      ../../pkgs/nix-unshare.patch
    ];
  });
  fish = tryUpstream prev.fish (o: {
    doCheck = false;
    doInstallCheck=false;
  });
  openssh = tryUpstream prev.openssh (o: {
    doCheck = false;
    doInstallCheck=false;
  });
  # '/home_nfs/bguibertd/nix/store/qs8l94570y7mnykssscd4c32xl5ki4gz-openssh-8.8p1.drv'
  openssh_gssapi = tryUpstream prev.openssh_gssapi (o: {
    doCheck = false;
    doInstallCheck=false;
  });
  # libgpg-error> ./etc/t-argparse.conf:73: error getting current user's name: System error w/o
  # errno
  libgpg-error = prev.libgpg-error.overrideAttrs (attrs: {
    doCheck = false;
    doInstallCheck=false;
  });

  libuv = prev.libuv.overrideAttrs (attrs: {
    doCheck = false;
    doInstallCheck=false;
  });
  # test-getaddrinfo
  gnutls = prev.gnutls.overrideAttrs (attrs: {
    doCheck = false;
    doInstallCheck=false;
  });

  #go_bootstrap = tryUpstream prev.go_bootstrap (attrs: {
  #  prePatch = attrs.prePatch + ''
  #    sed -i '/TestChown/aif true \{ return\; \}' src/os/os_unix_test.go
  #  '';
  #});
  #go_1_15 = tryUpstream prev.go_1_15 (attrs: {
  #  prePatch = attrs.prePatch + ''
  #    sed -i '/TestChown/aif true \{ return\; \}' src/os/os_unix_test.go
  #    sed -i '/TestFileChown/aif true \{ return\; \}' src/os/os_unix_test.go
  #    sed -i '/TestLchown/aif true \{ return\; \}' src/os/os_unix_test.go
  #  '';
  #});
  p11-kit = tryUpstream prev.p11-kit (attrs: {
    enableParallelBuilding = false;
    doCheck = false;
    doInstallCheck=false;
  });
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
      annexremote = lib.upgradeOverride python-super.annexremote (o: rec {
        version = "1.3.1";

        # use fetchFromGitHub instead of fetchPypi because the test suite of
        # the package is not included into the PyPI tarball
        src = fetchFromGitHub {
          rev = "v${version}";
          owner = "Lykos153";
          repo = "AnnexRemote";
          sha256 = "sha256-CM9Xe6a/Bt0tWdqVDGAqtl5qqQYwvcbzKFj1xoLz0Hs=";
        };

      });
    })
  ];

  patchelf = prev.patchelf.overrideAttrs ( attrs: {
    configureFlags = "--with-page-size=65536";
  });


}

