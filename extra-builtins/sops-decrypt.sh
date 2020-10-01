#!/usr/bin/env bash
set -x
encFile="$1"
workfile=$(mktemp)
trap "{ rm -f "$workfile"; }" EXIT

(
  umask 077
  @sops@/bin/sops --extract '["data"]' -d "$encFile" > "$workfile"
)

nix-instantiate --eval --strict -E "{ success=true; value=builtins.readFile $workfile; }"

