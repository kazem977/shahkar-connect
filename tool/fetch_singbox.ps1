# Download the official Windows sing-box release into native/bin/ (gitignored).
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

$ver = if ($env:SINGBOX_VERSION) { $env:SINGBOX_VERSION } else { "1.12.12" }
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
$asset = "sing-box-$ver-windows-$arch"
$url = "https://github.com/SagerNet/sing-box/releases/download/v$ver/$asset.zip"
$dest = Join-Path (Get-Location) "native\bin"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$tmp = Join-Path $env:TEMP ("shahkar-singbox-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp "sing-box.zip"
    Write-Host "Fetching $url"
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $exe = Get-ChildItem -Path $tmp -Recurse -Filter "sing-box.exe" | Select-Object -First 1
    if (-not $exe) { throw "sing-box.exe not found in archive" }
    Copy-Item $exe.FullName (Join-Path $dest "sing-box.exe") -Force
    $wintun = Get-ChildItem -Path $tmp -Recurse -Filter "wintun.dll" | Select-Object -First 1
    if ($wintun) {
        Copy-Item $wintun.FullName (Join-Path $dest "wintun.dll") -Force
    }
    Write-Host "Installed native/bin/sing-box.exe"
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
