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
url="https://github.com/SagerNet/sing-box/releases/download/v${ver}/${asset}.tar.gz"
echo "Fetching $url"
tmp="$(mktemp -d)"
curl -fsSL "$url" | tar -xz -C "$tmp"
find "$tmp" -type f -name 'sing-box*' -exec cp {} native/bin/sing-box \;
chmod +x native/bin/sing-box || true
echo "Installed native/bin/sing-box"
