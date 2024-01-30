#!/bin/bash
set -euo pipefail

readonly TERRAGRUNT_INSTALL_DIR="/usr/local/bin"
mkdir -p "$TERRAGRUNT_INSTALL_DIR"

# Make sure we have write permissions to target directory before downloading
if [ ! -w "$TERRAGRUNT_INSTALL_DIR" ] ; then
	>&2 echo "User does not have write permission to folder: ${TERRAGRUNT_INSTALL_DIR}"
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

# Determine the version of terragrunt to install
readonly TERRAGRUNT_CONFIG_FILE="${SCRIPT_DIR}/../terragrunt/terragrunt_conf.yaml"
>&2 echo "Reading $TERRAGRUNT_CONFIG_FILE"
readonly TERRAGRUNT_VERSION="$(cat $TERRAGRUNT_CONFIG_FILE | grep '^terragrunt_required_version: ' | awk -F':' '{gsub(/^[[:space:]]*["]*|["]*[[:space:]]*$/,"",$2); print $2}')"
if [[ -z "$TERRAGRUNT_VERSION" ]]; then
	>&2 echo 'Unable to find version number'
	exit 1
fi

# Install terragrunt
readonly TERRAGRUNT_BIN="$TERRAGRUNT_INSTALL_DIR/terragrunt"
cd "$(mktemp -d)"
wget "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_${OS_IDENTIFIER}_amd64" -O terragrunt
rm -f "$TERRAGRUNT_BIN" || echo "Terragrunt is not installed."
cp terragrunt "$TERRAGRUNT_BIN"
chmod +x "$TERRAGRUNT_BIN"

# Cleanup
rm terragrunt
