#!/usr/bin/env bash
# Local lint + unit tests. Requires Flutter SDK on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v dart >/dev/null 2>&1 && ! command -v flutter >/dev/null 2>&1; then
  echo "Install Flutter, then re-run: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
flutter test
