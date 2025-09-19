#!/bin/zsh
set -eu

# 現在のスクリプトのディレクトリを取得
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Homebrew / Brewfile
BREW_SCRIPT="$CURRENT_DIR/macos/brew-install.sh"
if [ -f "$BREW_SCRIPT" ]; then
  zsh "$BREW_SCRIPT"
else
  echo "./macos/brew-install.sh not found at $BREW_SCRIPT"
fi

# 2. Dotfiles
DOTFILES_INSTALL="$CURRENT_DIR/dotfiles/install.sh"
if [ -f "$DOTFILES_INSTALL" ]; then
  zsh "$DOTFILES_INSTALL"
else
  echo "./dotfiles/install.sh not found at $DOTFILES_INSTALL"
fi

echo "✅ Setup complete!"
echo ""
