$env:PATH = "$HOME\.local\bin;$env:PATH"

$localProfile = Join-Path (Split-Path -Parent $PROFILE) "Microsoft.PowerShell_profile.local.ps1"
if (Test-Path -LiteralPath $localProfile) {
  . $localProfile
}
