#!/usr/bin/env bash
# Downloads the native pieces the Android app needs:
#   1. Aether core, android release   -> android/app/src/main/jniLibs/<abi>/libaether.so
#      and its Psiphon client           -> android/app/src/main/jniLibs/<abi>/libpsiphon.so (skip: WITH_PSIPHON=0)
#        arm64-v8a  (required)  - 64-bit ARM phones
#        armeabi-v7a (required) - 32-bit ARM phones
#        x86_64     (optional)  - emulators; skipped with a warning if the release has no such asset
#   2. hev-socks5-tunnel Android AAR  -> android/app/libs/hev-socks5-tunnel.aar
# Run from the project root after `flutter create`. Needs curl, tar, unzip, sha256sum.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/android/app"
[ -d "$APP" ] || { echo "android/app not found - run 'flutter create' first" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

asset_url() { # <repo> <regex on asset name>
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 \
    | grep -E "$2" | head -n1 || true
}

# ---- Aether core -----------------------------------------------------------
fetch_core() { # <archive suffix> <abi dir> <required: 1|0>
  local name="aether-android-$1.tar.gz" abi="$2" required="$3" url
  url="$(asset_url CluvexStudio/Aether "/${name}\$")"
  if [ -z "$url" ]; then
    if [ "$required" = 1 ]; then echo "release asset $name not found" >&2; exit 1; fi
    echo "[aether] WARNING: no $name in the latest release - $abi build will lack the core" >&2
    return 0
  fi
  echo "[aether] $url"
  mkdir -p "$TMP/$abi"
  curl -fL "$url" -o "$TMP/$name"
  if curl -fsSL "$url.sha256" -o "$TMP/$name.sha256"; then
    (cd "$TMP" && sha256sum -c "$name.sha256")
  else
    echo "[aether] WARNING: no .sha256 published for $name, checksum not verified" >&2
  fi
  tar -xzf "$TMP/$name" -C "$TMP/$abi" aether
  mkdir -p "$APP/src/main/jniLibs/$abi"
  install -m 755 "$TMP/$abi/aether" "$APP/src/main/jniLibs/$abi/libaether.so"
  echo "[aether] installed jniLibs/$abi/libaether.so"

  # The Psiphon client ships beside the core in pt/. Android only executes files from the native
  # library directory, hence the lib*.so name; the app points AETHER_PSIPHON_BIN at it (+~20 MB per ABI).
  if [ "${WITH_PSIPHON:-1}" = 1 ]; then
    if tar -xzf "$TMP/$name" -C "$TMP/$abi" pt/psiphon-tunnel-core 2>/dev/null; then
      install -m 755 "$TMP/$abi/pt/psiphon-tunnel-core" "$APP/src/main/jniLibs/$abi/libpsiphon.so"
      echo "[psiphon] installed jniLibs/$abi/libpsiphon.so"
    else
      echo "[psiphon] WARNING: pt/psiphon-tunnel-core not in $name - Psiphon will not work on $abi" >&2
    fi
  fi
}

fetch_core arm64  arm64-v8a 1
fetch_core armv7  armeabi-v7a 1
fetch_core x86_64 x86_64    0

# ---- hev-socks5-tunnel AAR -------------------------------------------------
AAR_URL="$(asset_url heiher/hev-socks5-tunnel '\.aar$')"
[ -n "$AAR_URL" ] || { echo "no .aar asset in the latest hev-socks5-tunnel release" >&2; exit 1; }
echo "[hev] $AAR_URL"
mkdir -p "$APP/libs"
curl -fL "$AAR_URL" -o "$APP/libs/hev-socks5-tunnel.aar"

# The Kotlin code calls hev.htproxy.TProxyService.TProxyStartService(String, int) etc.
# Print what the AAR really exposes so a mismatch is obvious.
unzip -p "$APP/libs/hev-socks5-tunnel.aar" classes.jar > "$TMP/classes.jar"
echo "[hev] classes in the AAR:"
unzip -l "$TMP/classes.jar" | awk '{print $4}' | grep '\.class$' || true
if command -v javap >/dev/null; then
  echo "[hev] signatures:"
  javap -cp "$TMP/classes.jar" hev.htproxy.TProxyService || \
    echo "[hev] hev.htproxy.TProxyService not found - adapt the import in CoreService.kt"
fi
echo "done."
