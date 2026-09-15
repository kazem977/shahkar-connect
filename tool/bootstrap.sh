#!/usr/bin/env bash
# Generate iOS/Android/desktop platform folders on a machine that has Flutter,
# then copy Shahkar VPN glue from native/.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Install Flutter, then re-run: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

flutter create . \
  --project-name shahkar_connect \
  --org com.shahkar.connect \
  --platforms=ios,android,windows,macos,linux

flutter pub get
if command -v python3 >/dev/null 2>&1; then
  python3 tool/patch_vpn_glue.py
else
  python tool/patch_vpn_glue.py
fi

echo "Ready. Next (laptop):"
echo "  ./tool/fetch_singbox.sh     # desktop binary (Git Bash)"
echo "  ./tool/fetch_singbox.ps1    # desktop binary (Windows PowerShell)"
echo "  ./tool/build_libbox.sh      # Android AAR / iOS xcframework (needs Go + NDK / Xcode)"
echo "  flutter run --dart-define-from-file=env/dev.env.example"
echo "Checklist: docs/LAPTOP.md"
