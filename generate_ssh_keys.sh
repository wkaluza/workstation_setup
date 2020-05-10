#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function main() {
  # Not strictly necessary, but helps ensure /dev/urandom is well seeded
  ensure_rng_tools_daemon_is_running

  local algorithm="ed25519"
  local rounds=1000
  local email="w-kaluza@tlen.pl"
  local today_yymmdd
  today_yymmdd="$(date +'%Y%m%d')"
  local purpose="engineering"
  local file_name="${purpose}_ssh_${algorithm}"

  ssh-keygen -t "${algorithm}" -a "${rounds}" -o -C "${email} ${purpose} ${today_yymmdd}" -f "${file_name}"
  mv "./${file_name}" "./${file_name}.secret"
}

# Entry point
main
