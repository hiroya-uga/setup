param(
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🍣 Setting up Windows ..."

$CURRENT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$GITCONFIG_LOCAL = "$HOME\.gitconfig.local"
# Path of the backed-up ~/.gitconfig, if the dotfiles step replaced one. Used to
# tell the user where to copy their old Git settings from.
$script:GITCONFIG_BACKUP = ""
$script:LAST_BACKUP = ""

function Install-File($src, $dst, [switch]$Force) {
  $script:LAST_BACKUP = ""
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
      $script:LAST_BACKUP = $bak
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
$script:GITCONFIG_BACKUP = $script:LAST_BACKUP
Install-File "$CURRENT_DIR\dotfiles\common\git\.gitignore_global" "$HOME\.gitignore_global" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\editor\.editorconfig" "$HOME\.editorconfig" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\editor\.prettierrc.js" "$HOME\.prettierrc.js" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\claude\settings.json" "$HOME\.claude\settings.json" -Force:$Force
Install-File "$CURRENT_DIR\dotfiles\common\claude\CLAUDE.md" "$HOME\.claude\CLAUDE.md" -Force:$Force
foreach ($persona in Get-ChildItem -LiteralPath "$CURRENT_DIR\dotfiles\common\claude\personas" -Filter *.md -File -ErrorAction SilentlyContinue) {
  Install-File $persona.FullName "$HOME\.claude\personas\$($persona.Name)" -Force:$Force
}
Install-File "$CURRENT_DIR\dotfiles\common\mise\config.toml" "$HOME\.config\mise\config.toml" -Force:$Force

function Set-Reg($path, $name, $value) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -Path $path -Force | Out-Null
  }
  Set-ItemProperty -LiteralPath $path -Name $name -Value $value -Type DWord
}

$applyReg = Read-Host "Apply registry tweaks (show extensions/hidden files, clipboard history, dark mode, hide recent apps)? [y/N]"
if ($applyReg -match "^[yY]") {
  $ExplorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-Reg $ExplorerAdvanced "HideFileExt" 0      # 拡張子を表示
  Set-Reg $ExplorerAdvanced "Hidden" 1           # 隠しファイルを表示
  Set-Reg $ExplorerAdvanced "Start_TrackProgs" 0 # スタートの「最近開いた項目」を非表示

  Set-Reg "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1 # クリップボード履歴

  Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 # ダークモード

  Write-Host "✅ Registry tweaks applied."
} else {
  Write-Host "⏭️  Skipped registry tweaks."
}

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
$gitIdentitySet = $false
if (Get-Command git -ErrorAction SilentlyContinue) {
  git config --file $GITCONFIG_LOCAL --get user.email *> $null
  $gitIdentitySet = ($LASTEXITCODE -eq 0)
}
if ($gitIdentitySet) {
  Write-Host "   👉 Git identity is set in ~/.gitconfig.local. Update it with:"
} else {
  Write-Host "   👉 Configure your Git identity in ~/.gitconfig.local:"
}
Write-Host '        git config --file ~/.gitconfig.local user.name "Your Name"'
Write-Host '        git config --file ~/.gitconfig.local user.email "you@example.com"'
Write-Host '        git config --file ~/.gitconfig.local user.signingkey "<key-id-or-path>"'
if ($script:GITCONFIG_BACKUP) {
  Write-Host "      Your previous ~/.gitconfig was backed up to:"
  Write-Host "        $script:GITCONFIG_BACKUP"
  Write-Host "      Copy any settings you want to keep (identity, aliases, ...) from there."
}
Write-Host "   👉 Add machine-specific mise overrides in ~/.config/mise/conf.d/*.toml"
Write-Host "   👉 Add machine-specific profile overrides in Microsoft.PowerShell_profile.local.ps1"
Write-Host ""
