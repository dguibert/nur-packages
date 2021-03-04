#!/usr/bin/env bash
set -euo pipefail
set -x
echo $0 $@ >&2

private_key="$1"
echo "$(echo "$private_key" | @wireguardtools@/bin/wg pubkey)"
