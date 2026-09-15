# Bootstrap Flutter platform trees and VPN glue on Windows.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Install Flutter, then re-run: https://docs.flutter.dev/get-started/install"
}

if (-not $env:PUB_HOSTED_URL) {
  try {
    Invoke-WebRequest -Uri "https://pub.dev/api/packages/flutter_lints" -UseBasicParsing -TimeoutSec 8 | Out-Null
  } catch {
    $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
    if (-not $env:FLUTTER_STORAGE_BASE_URL) {
      $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
    }
    Write-Host "pub.dev blocked; using $env:PUB_HOSTED_URL"
  }
}

flutter create . `
    --project-name shahkar_connect `
    --org com.shahkar.connect `
    --platforms=ios,android,windows,macos,linux

flutter pub get
python "$PSScriptRoot\patch_vpn_glue.py"

Write-Host "Ready. Next:"
Write-Host "  .\tool\fetch_singbox.ps1"
Write-Host "  flutter run -d windows --dart-define=SHAHKAR_API_BASE=https://YOUR-LAB-PANEL"
Write-Host "If pub.dev returns 403, set PUB_HOSTED_URL=https://pub.flutter-io.cn"
Write-Host "Checklist: docs/LAPTOP.md"
