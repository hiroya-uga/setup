# Setup

This repository sets up my development environment for **macOS** and **Windows** in one place.

## Layout

- `homebrew/Brewfile`: packages for macOS
- `scoop/scoopfile.json`: packages for Windows
- `scoop/bucket/*.json`: local Scoop manifests managed in this repo
- `dotfiles/common`: shared config for Git, editors, and Claude Code
- `dotfiles/macos`: macOS-specific dotfiles
- `dotfiles/windows`: Windows-specific dotfiles

## What it does

1. Installs packages
   - On **macOS**, installs Homebrew and packages from `homebrew/Brewfile`
   - On **Windows**, installs Scoop and packages from `scoop/scoopfile.json`
1. Deploys shared and OS-specific dotfiles from this repository

## Clone

```sh
git clone https://github.com/hiroya-uga/setup.git
cd setup
```

## How to run

Run the install script for your platform.

### macOS (zsh)

```sh
zsh ./install.sh
```

Use `--symlink` to link files instead of copying them.

### Windows (PowerShell)

```pwsh
./install.ps1
```

Use `-Force` to replace existing files.

## Local-only overrides

- Git identity: `~/.gitconfig.local`
- macOS shell: `~/.zshrc.local`
- Windows PowerShell: `Microsoft.PowerShell_profile.local.ps1`
