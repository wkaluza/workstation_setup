#!/usr/bin/env bash

set -euo pipefail

function main() {
  local encrypted_partition="$1"
  local dislocker_dir="$2"
  local mount_point="$3"
  local password="$4"

  sudo dislocker "${encrypted_partition}" -u${password} -- "${dislocker_dir}"
  sudo mount -o loop "${dislocker_dir}/dislocker-file" "${mount_point}"
}

# Entry point
main "$1" "$2" "$3" "$4"
