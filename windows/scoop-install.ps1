$CURRENT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Scoop 初期化スクリプトを呼び出す
$SCOOP_INSTALL = "$CURRENT_DIR\scoop\install-with-json.ps1"
if (Test-Path $SCOOP_INSTALL) {
  & $SCOOP_INSTALL
} else {
  Write-Error "./windows/scoop/install-with-json.ps1 not found at $SCOOP_INSTALL"
  exit 1
}
