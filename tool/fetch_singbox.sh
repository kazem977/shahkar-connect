#!/usr/bin/env bash
# Download an official sing-box release into native/bin/ (gitignored).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p native/bin
ver="${SINGBOX_VERSION:-1.12.12}"
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
esac
case "$os" in
  darwin) os=darwin ;;
  linux) os=linux ;;
  mingw*|msys*|cygwin*) os=windows ;;
esac
asset="sing-box-${ver}-${os}-${arch}"
base="https://github.com/SagerNet/sing-box/releases/download/v${ver}"
tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

if [[ "$os" == windows ]]; then
  url="${base}/${asset}.zip"
  echo "Fetching $url"
  curl -fsSL "$url" -o "$tmp/sb.zip"
  if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
  "$PY" - "$tmp/sb.zip" "$tmp" <<'PY'
import sys, zipfile
from pathlib import Path
zf_path, dest = Path(sys.argv[1]), Path(sys.argv[2])
with zipfile.ZipFile(zf_path) as zf:
    zf.extractall(dest)
PY
else
  url="${base}/${asset}.tar.gz"
  echo "Fetching $url"
  curl -fsSL "$url" | tar -xz -C "$tmp"
fi

found="$(find "$tmp" -type f \( -name 'sing-box' -o -name 'sing-box.exe' \) | head -n 1 || true)"
if [[ -z "$found" ]]; then
  echo "sing-box binary not found in archive" >&2
  exit 1
fi
if [[ "$os" == windows ]]; then
  cp "$found" native/bin/sing-box.exe
  wintun="$(find "$tmp" -type f -name 'wintun.dll' | head -n 1 || true)"
  if [[ -n "$wintun" ]]; then
    cp "$wintun" native/bin/wintun.dll
  fi
  echo "Installed native/bin/sing-box.exe"
else
  cp "$found" native/bin/sing-box
  chmod +x native/bin/sing-box || true
  echo "Installed native/bin/sing-box"
fi
