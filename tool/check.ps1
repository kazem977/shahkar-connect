# Local lint + unit tests on Windows. Requires Flutter SDK on PATH.
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
    $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
  }
}

flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
flutter test
