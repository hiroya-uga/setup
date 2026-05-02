if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  iwr -useb get.scoop.sh | iex
}

$Buckets = @(
  @{ Name="main" },
  @{ Name="extras" }
)

$buckets = @(scoop bucket list | Select-Object -Skip 2 |
    ConvertFrom-String -PropertyNames Name, Source -Delimiter '\s{2,}')

foreach ($bucket in $Buckets) {
  if (-not ($buckets.Name -contains $bucket.Name)) {
    scoop bucket add $($bucket.Name)
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$json = Get-Content (Join-Path $scriptDir "scoopfile.json") -Raw | ConvertFrom-Json
$installed = scoop list

Write-Host "🍣 Installing packages from $scriptDir\scoopfile.json ..."

$packages = @()
$localManifests = @()

foreach ($app in $json.apps) {
  $manifestPath = Join-Path $scriptDir "bucket\$app.json"
  if (Test-Path -LiteralPath $manifestPath) {
    $localManifests += [pscustomobject]@{
      Name = $app
      Path = $manifestPath
    }
  } else {
    $packages += $app
  }
}

$notInstalled = @($packages | Where-Object {
  -not ($installed | Select-String -SimpleMatch $_)
})

if ($notInstalled.Count -gt 0) {
  Write-Host "   $($notInstalled -join ' ')"
  & scoop install @notInstalled
} else {
  Write-Host "All standard packages are already installed"
}

foreach ($manifest in $localManifests) {
  if ($installed | Select-String -SimpleMatch $manifest.Name) {
    Write-Host "$($manifest.Name) is already installed"
    continue
  }

  Write-Host "   $($manifest.Name) (local manifest)"
  & scoop install $manifest.Path
}

Write-Host "✅ Scoop installation completed!"
Write-Host ""
