#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function set_app_security() {
  print_trace

  local pin="$1"
  local puk="$2"
  local piv_mgmt_key="$3"

  local default_pin="123456"
  local default_puk="12345678"
  local default_mgmt_key="010203040506070801020304050607080102030405060708"

  ykman fido set-pin --new-pin "${pin}"
  sleep 1

  ykman oath set-password --new-password "${pin}"
  sleep 1

  ykman piv change-pin \
    --new-pin "${pin}" \
    --pin "${default_pin}"
  sleep 1

  ykman piv change-puk \
    --new-puk "${puk}" \
    --puk "${default_puk}"
  sleep 1

  ykman piv change-management-key \
    --new-management-key "${piv_mgmt_key}" \
    --management-key "${default_mgmt_key}"
  sleep 1
}

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

function adjust_config() {
  print_trace

  log_info "Enable NFC for all apps"
  ykman config nfc --force --enable-all
  sleep 1

  log_info "Enable USB for all apps"
  ykman config usb --force --enable-all
  sleep 1

  log_info "Enable USB touch-to-eject"
  ykman config usb --force --touch-eject
  sleep 1

  log_info "Set USB auto-eject timeout"
  ykman config usb --force --autoeject-timeout 14400
  sleep 1

  log_info "Set USB challenge-response timeout"
  ykman config usb --force --chalresp-timeout 30
  sleep 1
}

function ensure_unlocked_config() {
  print_trace

  local config_lock_code="$1"

  if ! ykman config set-lock-code --clear --lock-code "${config_lock_code}" >/dev/null 2>&1; then
    sleep 1
    ykman config set-lock-code --clear >/dev/null
  fi
  sleep 1
}

function lock_config() {
  print_trace

  local config_lock_code="$1"

  ykman config set-lock-code --new-lock-code "${config_lock_code}"
  sleep 1
}

function main() {
  local config_lock_code="$1"
  local pin="$2"
  local puk="$3"
  local piv_mgmt_key="$4"

  reset_yubikey_apps
  ensure_unlocked_config "${config_lock_code}"
  adjust_config
  lock_config "${config_lock_code}"
}

# Entry point
main "$1" "$2" "$3" "$4"
