#!/usr/bin/env bash

set -euo pipefail

function tagged_log_message_() {
  local tag="$1"
  local message="$2"

  echo "$tag: $message"
}

function log_trace() {
  local message="$1"

  tagged_log_message_ "[***TRACE***]" "$message"
}

function log_info() {
  local message="$1"

  tagged_log_message_ "INFO" "$message"
}

function log_warning() {
  local message="$1"

  tagged_log_message_ "WARNING" "$message"
}

function log_error() {
  local message="$1"

  tagged_log_message_ "ERROR" "$message"
}

function print_trace() {
  local trace="Entered ${FUNCNAME[1]} on line ${BASH_LINENO[1]} of ${BASH_SOURCE[2]}"

  log_trace "$trace"
}

function ensure_rng_tools_daemon_is_running() {
  if ! pgrep --exact "rngd" >/dev/null; then
    log_error "rngd is not running"
    exit 1
  fi
}
