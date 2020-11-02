#!/usr/bin/env bash
set -x
encFile="$1"

(
  umask 077
  if test -e "$encFile"; then
    @sops@/bin/sops --extract '["data"]' -d "$encFile"
  else
    echo "{ success=false; }"
  fi
)
