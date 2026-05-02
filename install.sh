#!/bin/zsh
set -eu

echo "🍣 Setting up macOS ..."

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
USE_SYMLINK=false
FORCE_OVERWRITE=false

usage() {
  echo "Usage: zsh ./install.sh [--symlink] [--force]"
}

for arg in "$@"; do
  case "$arg" in
    --symlink) USE_SYMLINK=true ;;
    --force) FORCE_OVERWRITE=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

install_file() {
  local src=$1
  local dst=$2

  mkdir -p "$(dirname "$dst")"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [[ "$FORCE_OVERWRITE" == "true" ]]; then
      rm -f "$dst"
    else
      local bak="${dst}_bak_$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$bak"
      echo "Backed up existing file: $dst -> $bak"
    fi
  fi

  if [[ "$USE_SYMLINK" == "true" ]]; then
    ln -s "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
}

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "🍣 Installing packages from $CURRENT_DIR/homebrew/Brewfile ..."
brew bundle --file="$CURRENT_DIR/homebrew/Brewfile"
echo "✅ Brew installation completed!"

install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zshrc" "$HOME/.zshrc"
install_file "$CURRENT_DIR/dotfiles/common/git/.gitconfig" "$HOME/.gitconfig"
install_file "$CURRENT_DIR/dotfiles/common/git/.gitignore_global" "$HOME/.gitignore_global"
install_file "$CURRENT_DIR/dotfiles/common/editor/.editorconfig" "$HOME/.editorconfig"
install_file "$CURRENT_DIR/dotfiles/common/editor/.prettierrc.js" "$HOME/.prettierrc.js"
install_file "$CURRENT_DIR/dotfiles/common/claude/settings.json" "$HOME/.claude/settings.json"

SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

clone_skill() {
  local repo=$1
  local name=$2
  local dest="$SKILLS_DIR/$name"

  if [ -d "$dest" ]; then
    echo "Skill already exists, skipping: $dest"
  else
    git clone "$repo" "$dest"
  fi
}

clone_skill "git@github.com:uga-skills/git-commit.git" "git-commit"
clone_skill "git@github.com:uga-skills/review-markup.git" "review-markup"

if [[ "$USE_SYMLINK" == "true" ]]; then
  echo "✅ Dotfiles have been linked!"
else
  echo "✅ Dotfiles have been copied!"
fi
echo "   👉 Configure your Git identity in ~/.gitconfig.local"
echo "   👉 Add machine-specific shell overrides in ~/.zshrc.local"
echo ""
