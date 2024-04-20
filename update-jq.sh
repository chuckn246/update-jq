#!/bin/sh

# Description: Download, verify and install jq binary on Linux and Mac
# Author: Chuck Nemeth
# https://jqlang.github.io/jq/

# VARIABLES
bin_dir="$HOME/.local/bin"
man_dir="$HOME/.local/share/man/man1"
tmp_dir="$(mktemp -d /tmp/jq.XXXXXXXX)"

if command -v jq >/dev/null; then
  jq_installed_version="$(jq --version)"
else
  jq_installed_version="Not Installed"
fi

jq_version_number="$(curl -Ls https://api.github.com/repos/jqlang/jq/releases/latest | \
                     awk -F': ' '/tag_name/ { gsub(/\"|jq-|\,/,"",$2); print $2 }')"
jq_version="jq-${jq_version_number}"
jq_url="https://github.com/jqlang/jq/releases/download/${jq_version}"
jq_man_url="https://raw.githubusercontent.com/jqlang/jq/master/jq.1.prebuilt"
jq_man="jq.1"

sum_file="sha256sum.txt"


# FUNCTIONS
# Define clean_up function
clean_up () {
  case "${2}" in
    [dD]|[dD]ebug)
      printf '%s\n' "Exiting without deleting files from ${tmp_dir}"
      exit "${1}"
      ;;
    *)
      printf '%s\n' "Cleaning up install files"
      cd && rm -rf "${tmp_dir}"
      exit "${1}"
      ;;
  esac
}

# colored output
code_grn () { tput setaf 2; printf '%s\n' "${1}"; tput sgr0; }
code_red () { tput setaf 1; printf '%s\n' "${1}"; tput sgr0; }
code_yel () { tput setaf 3; printf '%s\n' "${1}"; tput sgr0; }


# OS CHECK
case "$(uname -s)" in
  "Darwin")
      case "$(uname -p)" in
        "arm")
          jq_binary="jq-macos-arm64"
          ;;
        *)
          jq_binary="jq-macos-amd64"
          ;;
      esac
    ;;
  "Linux")
    jq_binary="jq-linux-amd64"
    ;;
  *)
    code_red "[ERROR] Unsupported OS. Exiting"
    clean_up 1
esac


# PATH CHECK
case :$PATH: in
  *:"${bin_dir}":*)  ;;  # do nothing
  *)
    code_red "[ERROR] ${bin_dir} was not found in \$PATH!"
    code_red "Add ${bin_dir} to PATH or select another directory to install to"
    clean_up 1
    ;;
esac


# VERSION CHECK
cd "${tmp_dir}" || exit

if [ "${jq_version}" = "${jq_installed_version}" ]; then
  printf '%s\n' "Installed Verision: ${jq_installed_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
  code_yel "[INFO] Already using latest version. Exiting."
  clean_up 0
else
  printf '%s\n' "Installed Verision: ${jq_installed_version}"
  printf '%s\n' "Latest Version: ${jq_version}"
fi


# DOWNLOAD
printf '%s\n' "Downloading the jq binary and verification files"
curl -sL -o "${tmp_dir}/${jq_binary}" "${jq_url}/${jq_binary}"
curl -sL -o "${tmp_dir}/${sum_file}" "${jq_url}/${sum_file}"


# VERIFY
# Verify shasum
printf '%s\n' "Verifying ${jq_binary}"
if ! shasum -qc --ignore-missing "${sum_file}"; then
  code_red "[ERROR] Problem with checksum!"
  clean_up 1
fi


# PREPARE
# Create directories
[ ! -d "${bin_dir}" ] && mkdir -p "${bin_dir}"
[ ! -d "${man_dir}" ] && mkdir -p "${man_dir}"


# INSTALL
# Install jq binary
if [ -f "${tmp_dir}/${jq_binary}" ]; then
  mv "${tmp_dir}/${jq_binary}" "${bin_dir}/jq"
  chmod 700 "${bin_dir}/jq"
fi


# MAN PAGE
printf '%s\n' "Installing jq man page"
curl -s -o "${man_dir}/${jq_man}" "${jq_man_url}"
chmod 600 "${man_dir}/${jq_man}"


# VERSION CHECK
code_grn "Done!"
code_grn "Installed Version: $(jq --version)"


# CLEAN UP
clean_up 0

# vim: ft=sh ts=2 sts=2 sw=2 sr et
