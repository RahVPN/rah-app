#!/usr/bin/env bash
# Downloads Aether and the hev tun2socks helper into linux/aether/.
# Usage: tools/linux/fetch_deps_linux.sh [x86_64|arm64] (default: this machine's arch)
#        WITH_PSIPHON=0 skips the Psiphon client; AETHER_TAG=v2.3.0 pins a release.
# Needs curl, tar, sha256sum.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
case "${1:-$(uname -m)}" in
  x86_64|amd64)  ARCH=x86_64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "unsupported arch: ${1:-$(uname -m)}" >&2; exit 1 ;;
esac
TAG="${AETHER_TAG:-latest}"
NAME="aether-linux-$ARCH.tar.gz"
if [ "$TAG" = latest ]; then
  URL="https://github.com/CluvexStudio/Aether/releases/latest/download/$NAME"
else
  URL="https://github.com/CluvexStudio/Aether/releases/download/$TAG/$NAME"
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "[aether] $URL"
curl -fL "$URL" -o "$TMP/$NAME"
if curl -fsSL "$URL.sha256" -o "$TMP/$NAME.sha256"; then
  (cd "$TMP" && sha256sum -c "$NAME.sha256")
else
  echo "[aether] WARNING: no .sha256 published, checksum not verified" >&2
fi

OUT="$ROOT/linux/aether"
rm -rf "$OUT"; mkdir -p "$OUT"
tar -xzf "$TMP/$NAME" -C "$TMP" aether
install -m 755 "$TMP/aether" "$OUT/aether"
if [ "${WITH_PSIPHON:-1}" = 1 ]; then
  if tar -xzf "$TMP/$NAME" -C "$TMP" pt/psiphon-tunnel-core 2>/dev/null; then
    mkdir -p "$OUT/pt"
    install -m 755 "$TMP/pt/psiphon-tunnel-core" "$OUT/pt/psiphon-tunnel-core"
  else
    echo "[psiphon] WARNING: pt/psiphon-tunnel-core not in the archive - Psiphon will not work" >&2
  fi
fi
HEV_TAG="${HEV_TAG:-2.18.0}"
case "$ARCH" in
  x86_64) HEV_ASSET=hev-socks5-tunnel-linux-x86_64 ;;
  arm64) HEV_ASSET=hev-socks5-tunnel-linux-arm64 ;;
esac
HEV_URL="https://github.com/heiher/hev-socks5-tunnel/releases/download/$HEV_TAG/$HEV_ASSET"
echo "[hev] $HEV_URL"
curl -fL "$HEV_URL" -o "$OUT/hev-socks5-tunnel"
chmod 755 "$OUT/hev-socks5-tunnel"
install -m 755 "$ROOT/tools/linux/linux_tun_routes.sh" "$OUT/rahvpn-tun-routes"
install -m 755 "$ROOT/tools/linux/linux_tun_supervisor.sh" "$OUT/rahvpn-tun-supervisor"
echo "[aether] installed in $OUT:"; ls -lR "$OUT" | sed 's/^/  /'
"$OUT/aether" --version 2>/dev/null || true
