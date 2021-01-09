#!/usr/bin/env bash

set -euo pipefail

function main() {
  local issuer="$1"
  local secret="$2"
  local account_id="$3"

  ykman oath add \
    --oath-type TOTP \
    --digits 6 \
    --algorithm SHA1 \
    --issuer "${issuer}" \
    --period 30 \
    --touch \
    --force \
    "${account_id}" \
    "${secret}"
}

# Entry point
main "$1" "$2" "$3"
