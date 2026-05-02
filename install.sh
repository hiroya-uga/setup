#!/bin/zsh
set -eu

echo "🍣 Setting up macOS ..."

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
USE_SYMLINK=true
FORCE_OVERWRITE=false
INSTALL_PERSONAL=false
DOTFILES_ONLY=false

usage() {
  echo "Usage: zsh ./install.sh [--symlink|--copy] [--force] [--personal|-p] [--dotfiles-only]"
}

for arg in "$@"; do
  case "$arg" in
    --symlink) USE_SYMLINK=true ;;
    --copy) USE_SYMLINK=false ;;
    --force) FORCE_OVERWRITE=true ;;
    --personal|-p) INSTALL_PERSONAL=true ;;
    --dotfiles-only|--skip-brew) DOTFILES_ONLY=true ;;
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

if [[ "$DOTFILES_ONLY" == "true" ]]; then
  echo "⏭️  Skipping Homebrew installation (--dotfiles-only)"
else
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  bundle_files=("$CURRENT_DIR/homebrew/Brewfile")

  if [[ "$INSTALL_PERSONAL" == "true" ]]; then
    bundle_files+=("$CURRENT_DIR/homebrew/Brewfile-personal")
  fi

  for bundle_file in "${bundle_files[@]}"; do
    if [[ ! -f "$bundle_file" ]]; then
      echo "Missing Brewfile: $bundle_file" >&2
      exit 1
    fi

    echo "🍣 Installing packages from ${bundle_file#$CURRENT_DIR/} ..."
    brew bundle --file="$bundle_file"
  done

  echo "✅ Brew installation completed!"
fi

install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zshenv" "$HOME/.zshenv"
install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zprofile" "$HOME/.zprofile"
install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zshrc" "$HOME/.zshrc"
install_file "$CURRENT_DIR/dotfiles/common/git/.gitconfig" "$HOME/.gitconfig"
install_file "$CURRENT_DIR/dotfiles/common/git/.gitignore_global" "$HOME/.gitignore_global"
install_file "$CURRENT_DIR/dotfiles/common/editor/.editorconfig" "$HOME/.editorconfig"
install_file "$CURRENT_DIR/dotfiles/common/editor/.prettierrc.js" "$HOME/.prettierrc.js"
install_file "$CURRENT_DIR/dotfiles/common/claude/settings.json" "$HOME/.claude/settings.json"
install_file "$CURRENT_DIR/dotfiles/common/mise/config.toml" "$HOME/.config/mise/config.toml"

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

if [[ "$DOTFILES_ONLY" == "true" ]]; then
  echo "⏭️  Skipping Claude skill clone (--dotfiles-only)"
else
  clone_skill "git@github.com:uga-skills/git-commit.git" "git-commit"
  clone_skill "git@github.com:uga-skills/review-markup.git" "review-markup"
fi

if [[ "$USE_SYMLINK" == "true" ]]; then
  echo "✅ Dotfiles have been linked!"
else
  echo "✅ Dotfiles have been copied!"
fi
echo "   👉 Configure your Git identity in ~/.gitconfig.local"
echo "   👉 Add machine-specific login shell overrides in ~/.zprofile.local"
echo "   👉 Add machine-specific shell env overrides in ~/.zshenv.local"
echo "   👉 Add machine-specific shell overrides in ~/.zshrc.local"
echo "   👉 Add machine-specific mise overrides in ~/.config/mise/conf.d/*.toml"
echo ""
