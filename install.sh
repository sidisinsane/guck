#!/usr/bin/env bash
# ---
# description: Installs guck for macOS and Linux.
# usage: curl -o- https://raw.githubusercontent.com/sidisinsane/guck/main/install.sh | bash
# exits:
#   0: success
#   1: fail
# ---

set -eo pipefail

GITHUB_USER="sidisinsane"
GITHUB_REPO="guck"
GUCK_DIR="$HOME/.guck"
BIN_DIR="$HOME/.local/bin"

# Detect OS
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
  Darwin*)             PLATFORM="darwin" ;;
  Linux*)              PLATFORM="linux" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *)                   echo "Error: Unsupported OS: $OS_TYPE"; exit 1 ;;
esac

# Detect shell config
if [[ "$SHELL" == */zsh ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
  SHELL_CONFIG="$HOME/.bashrc"
else
  SHELL_CONFIG="$HOME/.profile"
fi

# Clone or update repo
if [[ -d "$GUCK_DIR/.git" ]]; then
  echo "Updating guck in $GUCK_DIR..."
  git -C "$GUCK_DIR" pull --ff-only
else
  echo "Installing guck to $GUCK_DIR..."
  git clone "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$GUCK_DIR"
fi

# Make scripts executable
find "$GUCK_DIR" -name "*.sh" -exec chmod +x {} +
chmod +x "$GUCK_DIR/guck.sh"

# Create bin directory
mkdir -p "$BIN_DIR"

# Symlink dispatcher
ln -sf "$GUCK_DIR/guck.sh" "$BIN_DIR/guck"
echo "Symlinked guck to $BIN_DIR/guck"

# Add GUCK_DIR and PATH to shell config
if ! grep -q "GUCK_DIR" "$SHELL_CONFIG" 2>/dev/null; then
  echo "" >> "$SHELL_CONFIG"
  echo "# guck" >> "$SHELL_CONFIG"
  echo "export GUCK_DIR=\"$GUCK_DIR\"" >> "$SHELL_CONFIG"
fi

if ! grep -q "$BIN_DIR" "$SHELL_CONFIG" 2>/dev/null; then
  echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_CONFIG"
  echo "Done! Run 'source $SHELL_CONFIG' or restart your terminal to use guck."
else
  echo "guck is already in your PATH."
fi

echo "Installation complete!"
