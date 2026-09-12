#!/usr/bin/env bash
# Generate iOS/Android/desktop platform folders on a machine that has Flutter.
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
echo "Ready. Run: flutter run"
