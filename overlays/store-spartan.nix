final: prev: with final; let
in builtins.trace "spartan overlay" {
  #nixStore = builtins.trace "nixStore=/home_nfs_robin_ib/bguibertd/nix" "/home_nfs_robin_ib/bguibertd/nix";
  #nixStore = builtins.trace "nixStore=/home_nfs/bguibertd/nix" "/home_nfs/bguibertd/nix";
  nixStore = builtins.trace "nixStore=/scratch_na/users/bguibertd/nix" "/scratch_na/users/bguibertd/nix";
}

