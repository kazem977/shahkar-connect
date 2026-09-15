#!/usr/bin/env bash
# Generate iOS/Android/desktop platform folders on a machine that has Flutter,
# then copy Shahkar VPN glue from native/.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Install Flutter, then re-run: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

if [[ ! -d android || ! -d ios ]]; then
  flutter create . \
    --project-name shahkar_connect \
    --org com.shahkar.connect \
    --platforms=ios,android,windows,macos,linux
fi

flutter pub get
python3 tool/patch_vpn_glue.py

echo "Ready. Next (laptop):"
echo "  ./tool/fetch_singbox.sh     # desktop binary"
echo "  ./tool/build_libbox.sh      # Android AAR / iOS xcframework (needs Go + NDK / Xcode)"
echo "  flutter run --dart-define-from-file=env/dev.env.example"
echo "Checklist: docs/LAPTOP.md"
