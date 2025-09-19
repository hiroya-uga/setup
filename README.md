# Setup

This repository sets up my development environment for **macOS** and **Windows**.

## What it does

1. install packages
    - On **macOS**, installs Homebrew and packages from `macos/Brewfile`.
    - On **Windows**, installs Scoop and packages from `windows/scoop/scoopfile.json`.
1. Deploys personal dotfiles from the `dotfiles` submodule.

> [!NOTE]
> It uses the following submodules:
>
> -   `windows/scoop`: [hiroya-uga/scoop-hiroya-uga-bucket](https://github.com/hiroya-uga/scoop-hiroya-uga-bucket)
> -   `dotfiles`: [hiroya-uga/dotfiles](https://github.com/hiroya-uga/dotfiles)

## How to run

Clone this repository with submodules:

```sh
git clone --recursive https://github.com/hiroya-uga/setup.git && cd setup
```

And then, run the install file.

### macOS (zsh)

```sh
zsh ./install.sh
```

### Windows (PowerShell)

```pwsh
./install.ps1
```
