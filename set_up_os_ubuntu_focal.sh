#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function install_basics() {
  print_trace

  sudo apt-get update >/dev/null
  sudo apt-get upgrade -y >/dev/null
  sudo apt-get install -y \
    curl \
    wget \
    snapd \
    vim \
    scdaemon \
    rng-tools \
    vlc \
    git >/dev/null

  sudo mkdir -p /opt/jetbrains
}

function install_python() {
  print_trace

  sudo apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv >/dev/null

  python3 -u -m pip install --upgrade pip >/dev/null
  python3 -u -m pip install --upgrade certifi setuptools wheel >/dev/null
  python3 -u -m pip install --upgrade \
    pipenv >/dev/null
}

function install_docker() {
  print_trace

  if ! docker run --rm hello-world >/dev/null; then
    log_info "Installing docker ..."

    sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      gnupg-agent \
      software-properties-common >/dev/null

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
      sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn" apt-key add - >/dev/null
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/dev/null
    sudo apt-get update >/dev/null

    sudo apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io >/dev/null

    sudo systemctl enable docker

    # Create the docker group if it does not exist
    sudo getent group docker || sudo groupadd docker
    sudo usermod -aG docker "$USER" >/dev/null
  else
    log_info "docker is already installed"
  fi
}

function install_cpp_toolchains() {
  print_trace

  sudo apt-get install -y \
    make \
    ninja-build \
    gcc-8 \
    g++-8 \
    clang-9 \
    clang-tools-9 \
    clang-format-9 \
    clang-tidy-9 >/dev/null
}

function install_cmake() {
  print_trace

  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    wget >/dev/null

  curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null |
    sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn" apt-key add - >/dev/null
  sudo add-apt-repository \
    "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" >/dev/null
  sudo apt-get update >/dev/null

  sudo apt-get install -y cmake >/dev/null
}

function install_chrome() {
  print_trace

  if test -x "/opt/google/chrome/google-chrome"; then
    log_info "Google Chrome already installed"
  else
    wget --output-document ./chrome.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg --install ./chrome.deb
    rm ./chrome.deb
  fi
}

function install_yubico_utilities() {
  print_trace

  sudo add-apt-repository -y ppa:yubico/stable >/dev/null
  sudo apt-get update >/dev/null
  sudo apt-get install -y \
    yubikey-manager \
    yubioath-desktop \
    yubikey-personalization-gui >/dev/null
}

function install_tex_live() {
  print_trace

  sudo apt-get install -y \
    texlive-full
}

function configure_bash() {
  print_trace

  local config_preamble="# WK workstation setup"
  local bashrc_path="$HOME/.bashrc"

  if grep --silent "^${config_preamble}$" "${bashrc_path}"; then
    log_info "bash already configured"
  else
    echo "${config_preamble}" >>"${bashrc_path}"
    cat "./bashrc_append.sh" >>"${bashrc_path}"
  fi

  source "$bashrc_path"
}

function configure_git() {
  local pgp_signing_key_fingerprint="$1"

  print_trace

  git config --global user.email "w-kaluza@tlen.pl"
  git config --global user.name "Wojciech Kaluza"

  git config --global rebase.autosquash true
  git config --global pull.ff only
  git config --global merge.ff false

  git config --global log.showSignature true

  git config --global user.signingKey "${pgp_signing_key_fingerprint}"
  git config --global gpg.program gpg

  git config --global commit.gpgSign true
  git config --global merge.verifySignatures true
}

function configure_gpg() {
  print_trace

  local gpg_home="$HOME/.gnupg"
  local gpg_config_dir="gpg_config"
  local email="w-kaluza@tlen.pl"

  mkdir -p "$gpg_home"
  cp "./${gpg_config_dir}/gpg.conf" "$gpg_home"
  cp "./${gpg_config_dir}/gpg-agent.conf" "$gpg_home"

  gpg --import "./${gpg_config_dir}/engineering_pgp_primary_key_20200507.pub"
  gpg --expert --command-file "./${gpg_config_dir}/ultimate_trust_config" --edit-key "${email}"

  # Import GitHub's public key
  curl -fsSL https://github.com/web-flow.gpg | gpg --import
}

function press_any_key_to() {
  local action="$1"

  echo "Press any key to $action or Ctrl-c to quit"
  read -n 1 -s -r
}

function clean_up() {
  print_trace

  sudo apt-get autoremove -y >/dev/null
  press_any_key_to "reboot"
  sudo reboot
}

function main() {
  install_basics
  install_python
  install_docker
  install_cpp_toolchains
  install_cmake
  install_chrome
  install_yubico_utilities
  install_tex_live

  configure_bash
  configure_git "48E83769C79B5956A499ACB1CB87CBDEBBF89303"
  configure_gpg

  clean_up
}

# Entry point
main
