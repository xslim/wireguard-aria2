#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p "$HOME/.local/bin"
install -m 755 torrent "$HOME/.local/bin/torrent"
echo "Installed: $HOME/.local/bin/torrent"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo 'Add to ~/.zshrc: export PATH="$HOME/.local/bin:$PATH"' ;;
esac
