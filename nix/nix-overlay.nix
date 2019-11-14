final: prev: {
  nixStore = "/nix";
  #nixStore = "/home_nfs/bguibertd/nix";

  nix = if final.nixStore != "/nix" then prev.nix.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags ++ [
      "--with-store-dir=${final.nixStore}/store"
      "--localstatedir=${final.nixStore}/var"
      "--sysconfdir=${final.nixStore}/etc"
    ];
  }) else prev.nix;
}
