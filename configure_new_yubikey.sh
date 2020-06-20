#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function reset_yubikey_apps() {
  print_trace

  log_info "Reset FIDO"
  ykman fido reset --force
  sleep 1

  log_info "Reset OATH"
  ykman oath reset --force
  sleep 1

  log_info "Reset OpenPGP"
  ykman openpgp reset --force
  sleep 1

  log_info "Reset OTP slot 1"
  ykman otp delete --force 1
  sleep 1

  log_info "Reset OTP slot 2"
  ykman otp delete --force 2
  sleep 1

  log_info "Reset PIV"
  ykman piv reset --force
  sleep 1
}

function main() {
  reset_yubikey_apps
}

# Entry point
main
