#/usr/bin/env bash

store=$1; shift
drvs=$@

set -x
nix copy --from $store --derivation $drvs
results=$(nix-store -r --substituters $store $drvs)
nix copy --to $store $results
