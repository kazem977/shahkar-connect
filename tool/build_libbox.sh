#!/usr/bin/env bash
# Compile sagernet libbox with gomobile. Run on the laptop that has Go, Android
# NDK, and (for iOS) Xcode. Output stays gitignored.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v gomobile >/dev/null 2>&1; then
  echo "Install Go, then: go install golang.org/x/mobile/cmd/gomobile@latest && gomobile init" >&2
  exit 1
fi
mod="${LIBBOX_MODULE:-github.com/sagernet/sing-box/experimental/libbox}"
mkdir -p native/bin
if [[ "$(uname -s)" == "Darwin" ]]; then
  gomobile bind -target=ios -o native/bin/libbox.xcframework "$mod"
fi
if command -v ndk-build >/dev/null 2>&1 || [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
  gomobile bind -target=android -o native/bin/libbox.aar "$mod"
fi
echo "Artifacts in native/bin/ (not committed)."
