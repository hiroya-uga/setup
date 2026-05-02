#!/bin/zsh
set -eu

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
USE_SYMLINK=true
FORCE_OVERWRITE=false
INSTALL_PERSONAL=false
ONLY_MODE=""

usage() {
  cat <<EOF
Usage:
  zsh ./install.sh [options]

Set up macOS packages and dotfiles from this repository.

Options:
  --symlink              Symlink dotfiles into \$HOME (default)
  --copy                 Copy dotfiles instead of symlinking them
  --force                Replace existing files instead of backing them up
  -p, --personal         Include homebrew/Brewfile-personal
  -b, --brew-only        Install Homebrew packages only
  -d, --dotfiles-only    Install dotfiles only
  --skills-clone-only    Clone Claude skills only
  -h, --help             Show this help

Examples:
  zsh ./install.sh
  zsh ./install.sh -p
  zsh ./install.sh -b -p
  zsh ./install.sh -d --copy
  zsh ./install.sh --skills-clone-only

Notes:
  Only one of -b, --brew-only, -d, --dotfiles-only, and
  --skills-clone-only may be used.
  --copy only affects dotfile installation, so it has no effect with
  -b, --brew-only or --skills-clone-only.
  Existing files are backed up as *_bak_<timestamp> unless --force is used.
  Claude skills are cloned only during the default full setup.
  Homebrew is installed automatically when the brew step runs.
EOF
}

set_only_mode() {
  local mode=$1

  if [[ -n "$ONLY_MODE" && "$ONLY_MODE" != "$mode" ]]; then
    echo "Only one *-only option may be used at a time." >&2
    usage >&2
    exit 1
  fi

  ONLY_MODE="$mode"
}

for arg in "$@"; do
  case "$arg" in
    --symlink) USE_SYMLINK=true ;;
    --copy) USE_SYMLINK=false ;;
    --force) FORCE_OVERWRITE=true ;;
    -p|--personal) INSTALL_PERSONAL=true ;;
    -b|--brew-only) set_only_mode "brew" ;;
    -d|--dotfiles-only) set_only_mode "dotfiles" ;;
    --skills-clone-only) set_only_mode "skills" ;;
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

echo "🍣 Setting up macOS ..."

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

if [[ "$ONLY_MODE" == "dotfiles" || "$ONLY_MODE" == "skills" ]]; then
  if [[ "$ONLY_MODE" == "dotfiles" ]]; then
    echo "⏭️  Skipping Homebrew installation (-d / --dotfiles-only)"
  else
    echo "⏭️  Skipping Homebrew installation (--skills-clone-only)"
  fi
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

if [[ "$ONLY_MODE" == "dotfiles" ]]; then
  echo "⏭️  Skipping Claude skill clone (-d / --dotfiles-only)"
fi

if [[ "$ONLY_MODE" == "brew" || "$ONLY_MODE" == "skills" ]]; then
  if [[ "$ONLY_MODE" == "brew" ]]; then
    echo "⏭️  Skipping dotfiles installation (-b / --brew-only)"
  else
    echo "⏭️  Skipping dotfiles installation (--skills-clone-only)"
  fi
else
  install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zshenv" "$HOME/.zshenv"
  install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zprofile" "$HOME/.zprofile"
  install_file "$CURRENT_DIR/dotfiles/macos/zsh/.zshrc" "$HOME/.zshrc"
  install_file "$CURRENT_DIR/dotfiles/common/git/.gitconfig" "$HOME/.gitconfig"
  install_file "$CURRENT_DIR/dotfiles/common/git/.gitignore_global" "$HOME/.gitignore_global"
  install_file "$CURRENT_DIR/dotfiles/common/editor/.editorconfig" "$HOME/.editorconfig"
  install_file "$CURRENT_DIR/dotfiles/common/editor/.prettierrc.js" "$HOME/.prettierrc.js"
  install_file "$CURRENT_DIR/dotfiles/common/claude/settings.json" "$HOME/.claude/settings.json"
  install_file "$CURRENT_DIR/dotfiles/common/mise/config.toml" "$HOME/.config/mise/config.toml"
fi

SKILLS_DIR="$HOME/.claude/skills"
SKILLS_FILE="$CURRENT_DIR/config/claude-skills.txt"
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

clone_configured_skills() {
  if [[ ! -f "$SKILLS_FILE" ]]; then
    echo "Missing skills file: $SKILLS_FILE" >&2
    exit 1
  fi

  while read -r name repo; do
    if [[ -z "$name" || "$name" == \#* ]]; then
      continue
    fi

    if [[ -z "$repo" ]]; then
      echo "Invalid skill entry in ${SKILLS_FILE#$CURRENT_DIR/}: $name" >&2
      exit 1
    fi

    clone_skill "$repo" "$name"
  done < "$SKILLS_FILE"
}

if [[ -n "$ONLY_MODE" ]]; then
  if [[ "$ONLY_MODE" == "brew" ]]; then
    echo "⏭️  Skipping Claude skill clone (-b / --brew-only)"
  elif [[ "$ONLY_MODE" == "dotfiles" ]]; then
    :
  else
    clone_configured_skills
  fi
else
  clone_configured_skills
fi

if [[ "$ONLY_MODE" != "brew" && "$ONLY_MODE" != "skills" ]]; then
  if [[ "$USE_SYMLINK" == "true" ]]; then
    echo "✅ Dotfiles have been linked!"
  else
    echo "✅ Dotfiles have been copied!"
  fi
fi
echo "   👉 Configure your Git identity in ~/.gitconfig.local"
echo "   👉 Add machine-specific login shell overrides in ~/.zprofile.local"
echo "   👉 Add machine-specific shell env overrides in ~/.zshenv.local"
echo "   👉 Add machine-specific shell overrides in ~/.zshrc.local"
echo "   👉 Add machine-specific mise overrides in ~/.config/mise/conf.d/*.toml"
echo ""
