# Scoop

Windows packages and custom manifests managed inside this repository.

This directory contains:

- `scoopfile.json` for standard Scoop packages
- `bucket/*.json` for local custom manifests
- `install-with-json.ps1` for installing both

Run the repository root installer to apply both packages and dotfiles:

```pwsh
./install.ps1
```
