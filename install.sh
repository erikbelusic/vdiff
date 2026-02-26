#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/usr/local/bin"
LINK_NAME="vdiff"

# Check if vdiff.sh exists in the script directory
if [ ! -f "$SCRIPT_DIR/vdiff.sh" ]; then
    echo "Error: vdiff.sh not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Check if viewer.html exists
if [ ! -f "$SCRIPT_DIR/viewer.html" ]; then
    echo "Error: viewer.html not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Create symlink
if [ -L "$INSTALL_DIR/$LINK_NAME" ]; then
    echo "Updating existing symlink..."
    rm "$INSTALL_DIR/$LINK_NAME"
elif [ -e "$INSTALL_DIR/$LINK_NAME" ]; then
    echo "Error: $INSTALL_DIR/$LINK_NAME already exists and is not a symlink." >&2
    echo "Remove it manually and try again." >&2
    exit 1
fi

ln -s "$SCRIPT_DIR/vdiff.sh" "$INSTALL_DIR/$LINK_NAME"
echo "Installed: $INSTALL_DIR/$LINK_NAME -> $SCRIPT_DIR/vdiff.sh"
echo "You can now run 'vdiff' from any git repository."
