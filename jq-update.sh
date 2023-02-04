#!/bin/sh

# Description: Download, verify and install jq binary on Linux and Mac
# Author: Chuck Nemeth
# https://stedolan.github.io/jq/

bin_dir="$HOME/.local/bin"
man_dir="$HOME/.local/share/man/man1"
tmp_dir="$(mktemp -d /tmp/jq.XXXXXXXX)"

jq_installed_version="$(jq --version)"
jq_version_number="$(curl -s https://api.github.com/repos/stedolan/jq/releases/latest | \
                     awk -F': ' '/tag_name/ { gsub(/\"|jq-|\,/,"",$2); print $2 }')"
jq_version="jq-${jq_version_number}"
jq_url="https://github.com/stedolan/jq/releases/download/${jq_version}/"
jq_man="jq.1"

gpg_key="4FD701D6FA9B3D2DF5AC935DAF19040C71523402"
gpg_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release.key"

# Define clean_up function
clean_up () {
  printf "Would you like to delete the tmp_dir and the downloaded files? (Yy/Nn) "
  read -r choice
  case "${choice}" in
    [yY]|[yY]es)
      printf '%s\n\n' "Cleaning up install files"
      cd && rm -rf "${tmp_dir}"
      exit "${1}"
      ;;
    *)
      printf '%s\n\n' "Exiting without deleting files from ${tmp_dir}"
      exit "${1}"
      ;;
  esac
}


#######################
# OS CHECK
#######################
case "$(uname -s)" in
  "Darwin")
      case "$(uname -p)" in
        "arm")
          # Currently no arm releases
          # See: https://github.com/stedolan/jq/issues/2386
          jq_binary="jq-osx-amd64"
          ;;
        *)
          jq_binary="jq-osx-amd64"
          ;;
      esac
    ;;
  "Linux")
    jq_binary="jq-linux64"
    ;;
  *)
    tput setaf 1
    printf '%s\n\n' "[ERROR] Unsupported OS. Exiting"
    tput sgr0
    clean_up 1
esac


#######################
# PATH CHECK
#######################
case :$PATH: in
  *:"${bin_dir}":*)  ;;  # do nothing
  *)
    tput setaf 1
    printf '%s\n' "[ERROR] ${bin_dir} was not found in \$PATH!"
    printf '%s\n\n' "[ERROR] Add ${bin_dir} to PATH or select another directory to install to"
    tput sgr0
    clean_up 1
    ;;
esac


#######################
# VERSION CHECK
#######################
cd "${tmp_dir}" || exit

if [ "${jq_version}" = "${jq_installed_version}" ]; then
  tput setaf 3
  printf '%s\n\n' "[WARN] Already using latest version. Exiting."
  tput sgr0
  clean_up 0
else
  printf '%s\n' "Installed Verision: ${jq_installed_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
fi


#######################
# DOWNLOAD
#######################
printf '%s\n' "Downloading the jq binary and verification files"
sig_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/v${jq_version_number}/"
sig_file="${jq_binary}.asc"
checksums="sha256sum.txt"
sig_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/v${jq_version_number}/"

# Download the things
curl -sL -o "${tmp_dir}/${jq_binary}" "${jq_url}/${jq_binary}"
curl -sL -o "${tmp_dir}/${sig_file}" "${sig_url}/${sig_file}"
curl -sL -o "${tmp_dir}/${checksums}" "${sig_url}/${checksums}"


#######################
# VERIFY
#######################
# Import jq's gpg signing key
if ! gpg -k "${gpg_key}"; then
    printf '\n%s\n\n' "Importing GPG Key."
    gpg --fetch-keys "${gpg_url}"
fi

# Verify shasum and gpg signature
if shasum -qc "${checksums}" --ignore-missing; then
  if ! gpg --verify "${sig_file}" "${jq_binary}"; then
    tput setaf 1
    printf '\n%s\n\n' "[ERROR] Problem with signature!"
    tput sgr0
    clean_up 1
  fi
else
  tput setaf 1
  printf '\n%s\n\n' "[ERROR] Problem with checksum!"
  tput sgr0
  clean_up 1
fi


#######################
# PREPARE
#######################
# Create bin dir if it doesn't exist
if [ ! -d "${bin_dir}" ]; then
  mkdir -p "${bin_dir}"
fi


#######################
# INSTALL
#######################
# Install jq binary
if [ -f "${tmp_dir}/${jq_binary}" ]; then
  mv "${tmp_dir}/${jq_binary}" "${bin_dir}/jq"
  chmod 700 "${bin_dir}/jq"
fi


#######################
# VERSION CHECK
#######################
tput setaf 2
printf '\n%s\n' "Old Version: ${jq_installed_version}"
printf '%s\n\n' "Installed Version: $(jq --version)"
tput sgr0


#######################
# MAN PAGE
#######################
if [ ! -f "${man_dir}/${jq_man}" ]; then
  printf '\n%s\n' "I didn't compile the man page, but installed jq using homebrew and copied it from there"
  printf '%s\n' "brew install jq"
  printf '%s\n' "cp /opt/homebrew/Cellar/jq/1.6/share/man/man1/jq.1 ~/.local/share/man/man1"
  printf '%s\n\n' "brew uninstall jq"
fi


#######################
# CLEAN UP
#######################
clean_up 0

# vim: ft=sh ts=2 sts=2 sw=2 sr et