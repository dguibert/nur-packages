#!/usr/bin/env bash
set -x
encFile="$1"
key="${2:-data}"

(
  umask 077
  if test -e "$encFile"; then
    @sops@/bin/sops --extract "[\"$key\"]" -d "$encFile"
  else
    echo "{ success=false; }"
  fi
)
