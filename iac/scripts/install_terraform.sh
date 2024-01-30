#!/bin/bash
set -euo pipefail

readonly TERRAFORM_INSTALL_DIR="/usr/local/bin"
mkdir -p "$TERRAFORM_INSTALL_DIR"

# Make sure we have write permissions to target directory before downloading
if [ ! -w "$TERRAFORM_INSTALL_DIR" ] ; then
	>&2 echo "User does not have write permission to folder: ${TERRAFORM_INSTALL_DIR}"
	exit 1
fi

# Get the directory where the script is located
readonly SCRIPT_DIR="$(dirname $0)"

# Get the operating system identifier.
# May be one of "linux", "darwin", "freebsd" or "openbsd".
OS_IDENTIFIER="${1:-}"
if [[ -z "$OS_IDENTIFIER" ]]; then
	# POSIX compliant OS detection
	OS_IDENTIFIER=$(uname -s | tr '[:upper:]' '[:lower:]')
	>&2 echo "Detected OS Identifier: ${OS_IDENTIFIER}"
fi
readonly OS_IDENTIFIER

# Determine the version of terraform to install
readonly TERRAFORM_CONFIG_FILE="${SCRIPT_DIR}/../terragrunt/terragrunt_conf.yaml"
>&2 echo "Reading $TERRAFORM_CONFIG_FILE"
readonly TERRAFORM_VERSION="$(cat $TERRAFORM_CONFIG_FILE | grep '^terraform_required_version: ' | awk -F':' '{gsub(/^[[:space:]]*["]*|["]*[[:space:]]*$/,"",$2); print $2}')"
if [[ -z "$TERRAFORM_VERSION" ]]; then
	>&2 echo 'Unable to find version number'
	exit 1
fi

# Install terraform
readonly TERRAFORM_BIN="${TERRAFORM_INSTALL_DIR}/terraform"
cd "$(mktemp -d)"
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS_IDENTIFIER}_amd64.zip" -O terraform.zip
rm -f "${TERRAFORM_BIN}" || echo "Terraform is not installed."
unzip terraform.zip -d "$TERRAFORM_INSTALL_DIR"
chmod +x "${TERRAFORM_BIN}"

# Cleanup
rm terraform.zip
