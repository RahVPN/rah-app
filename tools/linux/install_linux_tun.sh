#!/usr/bin/env bash
# Check runtime tools and downloaded binaries required for Linux full-tunnel mode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [ -n "${RAH_AETHER_DIR:-}" ]; then
  AETHER_DIR="$RAH_AETHER_DIR"
elif [ -x "$ROOT/aether/aether" ]; then
  AETHER_DIR="$ROOT/aether"
else
  AETHER_DIR="$ROOT/linux/aether"
fi

for bin in "$AETHER_DIR/aether" "$AETHER_DIR/hev-socks5-tunnel"; do
  [ -x "$bin" ] || { echo "missing executable: $bin (run tools/linux/fetch_deps_linux.sh first)" >&2; exit 1; }
done
for helper in "$AETHER_DIR/rahvpn-tun-routes" "$AETHER_DIR/rahvpn-tun-supervisor"; do
  [ -x "$helper" ] || { echo "missing helper: $helper (run tools/linux/fetch_deps_linux.sh first)" >&2; exit 1; }
done
for cmd in pkexec setpriv ip flock; do
  command -v "$cmd" >/dev/null || {
    echo "$cmd not found; install polkit, util-linux, and iproute2." >&2
    exit 1
  }
done
[ -c /dev/net/tun ] || { echo "/dev/net/tun is unavailable" >&2; exit 1; }

echo "Linux TUN prerequisites are ready."
if [ ! -f /sys/fs/cgroup/cgroup.procs ] || ! command -v iptables >/dev/null || ! command -v ip6tables >/dev/null; then
  echo "Psiphon TUN additionally requires cgroup v2 and iptables/ip6tables for egress marking."
fi
