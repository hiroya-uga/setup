Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CURRENT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1. Scoop
$SCOOP_INSTALL = Join-Path $CURRENT_DIR "windows\scoop-install.ps1"
if (Test-Path $SCOOP_INSTALL) {
  & $SCOOP_INSTALL
} else {
  Write-Error "./windows/scoop-install.ps1 not found at $SCOOP_INSTALL"
}

# 2. Dotfiles
$DOTFILES_INSTALL = Join-Path $CURRENT_DIR "dotfiles\install.ps1"
if (Test-Path $DOTFILES_INSTALL) {
  & $DOTFILES_INSTALL
} else {
  Write-Error "./dotfiles/install.ps1 not found at $DOTFILES_INSTALL"
}

Write-Host "✅ Setup complete!"
Write-Host ""
