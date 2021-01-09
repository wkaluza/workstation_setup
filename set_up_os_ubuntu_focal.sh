#!/usr/bin/env bash

set -euo pipefail

source "./common.sh"

function ensure_not_sudo() {
  if test "0" -eq "$(id -u)"; then
    echo Do not run this as root
    exit 1
  fi
}

function install_basics() {
  print_trace

  sudo apt-get update >/dev/null
  sudo apt-get upgrade --with-new-pkgs -y >/dev/null
  sudo apt-get install -y \
    curl \
    wget \
    snapd \
    vim \
    scdaemon \
    rng-tools \
    vlc \
    jq \
    inkscape \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    dislocker \
    git >/dev/null
}

function install_jetbrains_toolbox() {
  print_trace

  local tar_gz_path="$1"

  local extract_target_name
  extract_target_name="$(basename "${tar_gz_path}" ".tar.gz")"
  local install_destination="/opt/jetbrains/jetbrains-toolbox"

  if ! test -x "${install_destination}"; then
    sudo mkdir -p "$(dirname "${install_destination}")"

    pushd "$(dirname "${tar_gz_path}")" >/dev/null
    tar -xzf "${tar_gz_path}"
    sudo cp \
      "./${extract_target_name}/$(basename "${install_destination}")" \
      "${install_destination}"

    sudo rm -rf "${tar_gz_path}"
    sudo rm -rf "./${extract_target_name}"
    popd >/dev/null
  else
    echo "Toolbox already installed at ${install_destination}"
  fi
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

  if ! docker --version >/dev/null; then
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
    sudo dpkg --install ./chrome.deb >/dev/null
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
    texlive-full >/dev/null
}

function install_golang() {
  print_trace

  local go_archive="go.tar.gz"
  local go_version="1.15.5"
  local download_url="https://dl.google.com/go/go${go_version}.linux-amd64.tar.gz"
  # Must match PATH update in bashrc_append.sh
  local target_dir="/usr/local"

  if ! test -d "${target_dir}/go"; then
    curl -fsSL --output "./${go_archive}" "${download_url}"
    sudo mv "./${go_archive}" "${target_dir}"

    pushd "${target_dir}"
    sudo tar -xzf "./${go_archive}"
    sudo rm "./${go_archive}"
    popd
  else
    echo "golang is already installed"
  fi
}

function install_nodejs() {
  print_trace

  curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs >/dev/null
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
  print_trace

  local pgp_primary_key_fingerprint="$1"

  git config --global user.email "wkaluza@protonmail.com"
  git config --global user.name "Wojciech Kaluza"

  git config --global rebase.autosquash true
  git config --global pull.ff only
  git config --global merge.ff false

  git config --global log.showSignature true

  git config --global user.signingKey "${pgp_primary_key_fingerprint}"
  git config --global gpg.program gpg

  git config --global commit.gpgSign true
  git config --global merge.verifySignatures true

  git config --global rerere.enabled true
}

function configure_gpg() {
  print_trace

  local pgp_primary_key_fingerprint="$1"

  local gpg_home="$HOME/.gnupg"
  local gpg_config_dir="gpg_config"

  mkdir -p "$gpg_home"
  cp "./${gpg_config_dir}/gpg.conf" "$gpg_home"
  cp "./${gpg_config_dir}/gpg-agent.conf" "$gpg_home"

  gpg --receive-keys "${pgp_primary_key_fingerprint}"
  cat "./${gpg_config_dir}/ownertrust" | gpg --import-ownertrust

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

  sudo apt-get update >/dev/null
  sudo apt-get upgrade --with-new-pkgs -y >/dev/null
  sudo apt-get autoremove -y >/dev/null
  sudo apt-get clean >/dev/null

  press_any_key_to "reboot"
  sudo reboot
}

function main() {
  local jetbrains_toolbox_tar_gz="$1"
  local pgp_primary_key_fingerprint="655032BAB18D09A2D3239451F24BE8916149A3C4"

  ensure_not_sudo

  install_basics
  install_jetbrains_toolbox "${jetbrains_toolbox_tar_gz}"
  install_python
  install_docker
  install_cpp_toolchains
  install_cmake
  install_chrome
  install_yubico_utilities
  install_tex_live
  install_golang
  install_nodejs

  configure_bash
  configure_git "${pgp_primary_key_fingerprint}"
  configure_gpg "${pgp_primary_key_fingerprint}"

  clean_up
}

# Entry point
main "$1"
