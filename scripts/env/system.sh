#!/usr/bin/env bash
# ---
# description: Reports OS, architecture, and shell of the current system.
# usage: system.sh
# exits:
#   0: success
#   1: unsupported OS or architecture
# ---

set -eo pipefail

# Detect OS
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
  Darwin*)             OS="darwin" ;;
  Linux*)              OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  *)                   echo "error: unsupported OS: $OS_TYPE" >&2; exit 1 ;;
esac

# Detect architecture
ARCH_TYPE=$(uname -m)
case "$ARCH_TYPE" in
  x86_64)        ARCH="x86_64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)             echo "error: unsupported architecture: $ARCH_TYPE" >&2; exit 1 ;;
esac

# Detect shell
case "$SHELL" in
  */zsh)  SHELL_NAME="zsh" ;;
  */bash) SHELL_NAME="bash" ;;
  */fish) SHELL_NAME="fish" ;;
  *)      SHELL_NAME=$(basename "$SHELL") ;;
esac

echo "os: ${OS}"
echo "arch: ${ARCH}"
echo "shell: ${SHELL_NAME}"
