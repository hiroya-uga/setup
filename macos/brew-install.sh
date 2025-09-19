#!/bin/sh
set -eu

DIR="$(cd "$(dirname "${0}")" && pwd)"

# Homebrew がインストールされているかチェック
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "🍣 Installing packages from Brewfile ..."
brew bundle --file="$DIR/Brewfile"
echo "✅ Brew installation completed!"
