final: prev: with final; let
in builtins.trace "lumi overlay" {
  nixStore = builtins.trace "nixStore=/users/dguibert/nix" "/users/dguibert/nix";

  pythonOverrides = prev.lib.composeOverlays [
    (prev.pythonOverrides or (_:_: {}))
    (python-self: python-super: {
      #annexremote = lib.narHash python-super.annexremote "1.6.0" "sha256-h03gkRAMmOq35zzAq/OuctJwPAbP0Idu4Lmeu0RycDc";
      flit-scm = lib.narHash python-super.flit-scm "1.7.0" "sha256-2nx9kWq/2TzauOW+c67g9a3JZ2dhBM4QzKyK/sqWOPo=";
    })
  ];
}
