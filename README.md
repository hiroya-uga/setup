# Setup

This repository sets up my development environment for **macOS** and **Windows** in one place.

## Layout

- `homebrew/Brewfile`: packages for macOS
- `homebrew/Brewfile-personal`: optional personal macOS packages
- `scoop/scoopfile.json`: packages for Windows
- `scoop/bucket/*.json`: local Scoop manifests managed in this repo
- `dotfiles/common`: shared config for Git, editors, Claude Code, and mise
- `dotfiles/macos`: macOS-specific dotfiles
- `dotfiles/windows`: Windows-specific dotfiles

## What it does

1. Installs packages
   - On **macOS**, installs Homebrew packages from `homebrew/Brewfile` plus an optional personal overlay
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

Symlinks are the default. Use `--copy` to copy files instead.
Use `-p` or `--personal` to include the optional personal Homebrew overlay.
Use `-d` or `--dotfiles-only` to skip Homebrew and only refresh dotfiles.

### Windows (PowerShell)

```pwsh
./install.ps1
```

Use `-Force` to replace existing files.

## Local-only overrides

- Git identity: `~/.gitconfig.local`
- macOS login shell: `~/.zprofile.local`
- macOS shell env: `~/.zshenv.local`
- macOS shell: `~/.zshrc.local`
- mise global config: `~/.config/mise/conf.d/*.toml`
- Windows PowerShell: `Microsoft.PowerShell_profile.local.ps1`
