#!/bin/sh

# Description: Download, verify and install jq binary on Linux and Mac
# Author: Chuck Nemeth
# https://stedolan.github.io/jq/

os="$(uname -s)"
bindir="$HOME/.local/bin"
tmpdir="$(mktemp -d /tmp/jq.XXXXXXXX)"

jq_version="1.6"
jq_current_version="$(jq --version)"
jq_url="https://github.com/stedolan/jq/releases/download/jq-${jq_version}/"

gpg_key="4FD701D6FA9B3D2DF5AC935DAF19040C71523402"
gpg_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release.key"


# Define clean_up function
clean_up () {
  printf "Would you like to delete the downloaded files? (Yy/Nn) "
  read -r choice
  case "${choice}" in
    [yY]|[yY]es)
      printf '%s\n\n' "Cleaning up install files"
      cd && rm -rf "${tmpdir}"
      ;;
    *)
      printf '%s\n\n' "Exiting without deleting files from ${tmpdir}"
      exit 0
      ;;
  esac
}


#######################
# OS CHECK
#######################
case "${os}" in
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
    printf '%s\n' "[ERROR] Unsupported OS. Exiting"
    exit 1
esac


#######################
# PATH CHECK
#######################
case :$PATH: in
  *:"${bindir}":*)  ;;  # do nothing
  *)
    tput setaf 1
    printf '%s\n' "[ERROR] ${bindir} was not found in \$PATH!"
    printf '%s\n' "[ERROR] Add ${bindir} to PATH or select another directory to install to"
    tput sgr0
    exit 1
    ;;
esac


#######################
# VERSION CHECK
#######################
cd "${tmpdir}" || exit

if [ "${jq_version}" = "${jq_current_version}" ]; then
  printf '%s\n' "[INFO] Already using latest version. Exiting."
  clean_up
  exit
else
  printf '%s\n' "Installed Verision: ${jq_current_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
fi


#######################
# DOWNLOAD
#######################
printf '%s\n' "Downloading jq binary"
sig_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/v${jq_version}/"
sig_file="${jq_binary}.asc"
checksums="sha256sum.txt"
sig_url="https://raw.githubusercontent.com/stedolan/jq/master/sig/v${jq_version}/"

# Download the things
curl -sL -o "${tmpdir}/${jq_binary}" "${jq_url}/${jq_binary}"
curl -sL -o "${tmpdir}/${sig_file}" "${sig_url}/${sig_file}"
curl -sL -o "${tmpdir}/${checksums}" "${sig_url}/${checksums}"


#######################
# VERIFY
#######################
# Import jq's gpg signing key
if ! gpg -k "${gpg_key}"; then
    printf '\n%s\n\n' "[INFO] Importing GPG Key."
    gpg --fetch-keys "${gpg_url}"
fi

# Verify shasum and gpg signature
if shasum -qc "${checksums}" --ignore-missing; then
  if ! gpg --verify "${sig_file}" "${jq_binary}"; then
    tput setaf 1
    printf '\n%s\n' "[ERROR] Problem with signature!"
    tput sgr0
    clean_up
    exit 1
  fi
else
  tput setaf 1
  printf '\n%s\n' "[ERROR] Problem with checksum!"
  tput sgr0
  clean_up
  exit 1
fi


#######################
# PREPARE
#######################
# Create bin dir if it doesn't exist
if [ ! -d "${bindir}" ]; then
  mkdir -p "${bindir}"
fi


#######################
# INSTALL
#######################
# Install jq binary
if [ -f "${tmpdir}/${jq_binary}" ]; then
  mv "${tmpdir}/${jq_binary}" "${bindir}/jq"
  chmod 700 "${bindir}/jq"
fi


#######################
# VERSION CHECK
#######################
tput setaf 2
printf '\n%s\n' "Old Version: ${jq_current_version}"
printf '%s\n\n' "Installed Version: $(jq --version)"
tput sgr0


#######################
# MAN PAGE
#######################
printf '%s\n' "I didn't compile the man page, but installed jq using homebrew and copied it from there"
printf '%s\n' "brew install jq"
printf '%s\n' "cp /opt/homebrew/Cellar/jq/1.6/share/man/man1/jq.1 ~/.local/share/man/man1"
printf '%s\n' "brew uninstall jq"


#######################
# CLEAN UP
#######################
clean_up

# vim: ft=sh ts=2 sts=2 sw=2 sr et