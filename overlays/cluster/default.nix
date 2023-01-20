final: prev: with prev; {
  lib = prev.lib.extend(final': prev': with final'; {
    fetchers = import ./lib/fetchers.nix { lib = prev'; };
    tryUpstream = drv: attrs: builtins.trace "broken upstream ${drv.name}" (drv.overrideAttrs attrs).overrideAttrs (o: {
      isBroken = isBroken drv;
    });
    # https://nixos.org/manual/nix/stable/language/builtins.html#builtins-tryEval
    #let e = { x = throw ""; }; in (builtins.tryEval (builtins.deepSeq e e)).success
    #if (builtins.tryEval (isBroken drv)).success
    #then (isBroken drv) # should fail and use our override
    #else drv.overrideAttrs attrs;
    dontCheck = drv: drv.overrideAttrs (o: {
      doCheck = false;
      doInstallCheck = false;
    });
    upstreamFails = drv: if ! (nixStore == "/nix") then tryUpstream drv (o: {
      doCheck = false;
      doInstallCheck = false;
    }) else drv;


  #nix = if nixStore == "/nix" then prev.nix
  #  else final.lib.upstreamFails prev.nix;
  nix = final.lib.dontCheck prev.nix;
  nix_2_3 = final.lib.upstreamFails prev.nix_2_3;
  nixStable = final.lib.upstreamFails prev.nixStable;
  nixos-option = null;
  fish = final.lib.dontCheck prev.fish;

  openssh = final.lib.dontCheck prev.openssh;

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-self: python-super: {
      flask-limiter = lib.upgradeOverride python-super.flask-limiter (o: rec {
        version = "2.6.2";

        src = fetchFromGitHub {
          owner = "alisaifee";
          repo = "flask-limiter";
          rev = version;
          sha256 = "sha256-eWOdJ7m3cY08ASN/X+7ILJK99iLJJwCY8294fwJiDew=";
        };
      });
      annexremote = lib.upgradeOverride python-super.annexremote (o: rec {
        version = "1.6.0";

        # use fetchFromGitHub instead of fetchPypi because the test suite of
        # the package is not included into the PyPI tarball
        src = fetchFromGitHub {
          rev = "v${version}";
          owner = "Lykos153";
          repo = "AnnexRemote";
          sha256 = "sha256-h03gkRAMmOq35zzAq/OuctJwPAbP0Idu4Lmeu0RycDc=";
        };

      });
      dnspython = final.lib.upstreamFails python-super.dnspython;
    })
  ];

  datalad = lib.upgradeOverride prev.datalad (o: rec {
    version = "0.16.5";
    src = fetchFromGitHub {
      owner = "datalad";
      repo = "datalad";
      rev = "refs/tags/${version}";
      sha256 = "sha256-F5UFW0/XqntrHclpj3TqoAwuHJbiiv5a7/4MnFoJ1dE=";
    };
  });
}
