# build.ps1 - builds the Attacca release zip into dist\.
# Attacca is plain PowerShell plus two .cmd launchers, so the zip is just the
# tracked files in one Attacca\ folder. Works in Windows PowerShell 5.1 and 7.
#
# Version: -Version, else the pushed tag (v2026.10.12 -> 2026.10.12), else today.
param([string]$Version)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'

if (-not $Version) {
    $Version = if ($env:GITHUB_REF_NAME -match '^v(.+)$') { $Matches[1] } else { Get-Date -Format 'yyyy.M.d' }
}
Write-Host "Building Attacca $Version"

$files = @(git -C $root ls-files) | Where-Object { $_ -notmatch '^(\.git|build\.ps1$)' }
if ($files.Count -eq 0) { throw 'git ls-files returned nothing - run from a git checkout' }

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
$stage = Join-Path $dist 'Attacca'
foreach ($f in $files) {
    $to = Join-Path $stage $f
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item (Join-Path $root $f) $to
}

$zip = Join-Path $dist "Attacca-$Version.zip"
Compress-Archive -Path $stage -DestinationPath $zip -Force
Write-Host "Done: $zip"
