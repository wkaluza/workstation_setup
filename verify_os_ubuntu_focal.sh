#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function verify_jetbrains_toolbox() {
  local toolbox_app_path="/opt/jetbrains/toolbox"

  if ! test -x "$toolbox_app_path"; then
    log_error "Could not find executable at $toolbox_app_path . Install the JetBrains Toolbox App"
    exit 1
  fi

  $toolbox_app_path --version >/dev/null
}

function main() {
  git --version >/dev/null
  pipenv --version >/dev/null
  docker --version >/dev/null
  docker run hello-world >/dev/null
  cmake --version >/dev/null
  clang-9 --version >/dev/null
  clang++-9 --version >/dev/null
  gcc-8 --version >/dev/null
  g++-8 --version >/dev/null
  clang-format-9 --version >/dev/null
  clang-tidy-9 --version >/dev/null

  ensure_rng_tools_daemon_is_running
  verify_jetbrains_toolbox

  log_info "Verification successful"
}

# Entry point
main
