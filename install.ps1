param(
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🍣 Setting up Windows ..."

$CURRENT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

function Install-File($src, $dst, [switch]$Force) {
  $parent = Split-Path -Parent $dst
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  if (Test-Path -LiteralPath $dst) {
    if ($Force) {
      Remove-Item -LiteralPath $dst -Force
    } else {
      $timestamp = Get-Date -Format "yyyyMMddHHmmss"
      $bak = "${dst}_bak_${timestamp}"
      Move-Item -LiteralPath $dst -Destination $bak
      Write-Host "Backed up existing file: $dst -> $bak"
    }
  }

  Copy-Item -LiteralPath $src -Destination $dst
}

$SCOOP_INSTALL = Join-Path $CURRENT_DIR "scoop\install-with-json.ps1"
if (Test-Path -LiteralPath $SCOOP_INSTALL) {
  & $SCOOP_INSTALL
} else {
  Write-Error "./scoop/install-with-json.ps1 not found at $SCOOP_INSTALL"
}

Install-File "$CURRENT_DIR\dotfiles\windows\powershell\Microsoft.PowerShell_profile.ps1" $PROFILE -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\git\.gitconfig" "$HOME\.gitconfig" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\git\.gitignore_global" "$HOME\.gitignore_global" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\editor\.editorconfig" "$HOME\.editorconfig" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\editor\.prettierrc.js" "$HOME\.prettierrc.js" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\claude\settings.json" "$HOME\.claude\settings.json" -Force:$Force

$SkillsDir = "$HOME\.claude\skills"
if (-not (Test-Path -LiteralPath $SkillsDir)) {
  New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

function Clone-Skill($repo, $name) {
  $dest = Join-Path $SkillsDir $name
  if (Test-Path -LiteralPath $dest) {
    Write-Host "Skill already exists, skipping: $dest"
  } else {
    git clone $repo $dest
  }
}

Clone-Skill "git@github.com:uga-skills/git-commit.git" "git-commit"
Clone-Skill "git@github.com:uga-skills/review-markup.git" "review-markup"

Write-Host "✅ Dotfiles have been copied!"
Write-Host "   👉 Configure your Git identity in ~/.gitconfig.local"
Write-Host "   👉 Add machine-specific profile overrides in Microsoft.PowerShell_profile.local.ps1"
Write-Host ""
