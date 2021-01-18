# Nix configuration for this host

This is a work-in-progress for providing nix to a machine where I'm not root and therefore can't install Nix in /nix.

## How to use it

```
   nix develop
```

```
   mkdir -pv ~/$ENVRC
   nix build .#nixBinaryTarball
```

Or if the directory exist already (~/$ENVRC)

```
   nix run .# -- build .#nixBinaryTarball
```

## Build Home config

```
nix build .#home-bguibertd.x86_64-linux.activationPackage --impure -L
nix copy --to ssh://spartan $(readlink ./result)
ssh spartan NIX_STATE_DIR=/home_nfs_robin_ib/bguibertd/nix/var/nix/ $(readlink ./result)/activate
```

One line:
```
nix build .#home-bguibertd.x86_64-linux.activationPackage --impure -L && nix copy --to ssh://spartan $(readlink ./result) && ssh spartan NIX_STATE_DIR=/home_nfs_robin_ib/bguibertd/nix/var/nix/ $(readlink ./result)/activate
```
