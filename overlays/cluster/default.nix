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

    narHash = pkg: version: hash: builtins.trace "${pkg.name} with new hash: ${hash}" lib.upgradeOverride pkg (_: {
      inherit version;
      src = pkg.src.overrideAttrs (_: {
        outputHash = hash;
      });
    });
  });

  #nix = if nixStore == "/nix" then prev.nix
  #  else final.lib.upstreamFails prev.nix;
  nix = final.lib.dontCheck prev.nix;
  nix_2_3 = final.lib.upstreamFails prev.nix_2_3;
  nixStable = final.lib.upstreamFails prev.nixStable;
  nixos-option = null;
  fish = final.lib.dontCheck prev.fish;

  openssh = final.lib.dontCheck prev.openssh;

}
