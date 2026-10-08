#!/usr/bin/env bash
# Installs/removes the dedicated policy-routing rules used by RahVPN's TUN.
set -euo pipefail

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
IP="$(command -v ip)"
TUN=rah0
TABLE=51919
PRIORITY=11919
MARK=1819

down() {
  "$IP" rule del priority "$PRIORITY" lookup "$TABLE" 2>/dev/null || true
  "$IP" -6 rule del priority "$PRIORITY" lookup "$TABLE" 2>/dev/null || true
  "$IP" rule del priority "$((PRIORITY - 1))" fwmark "$MARK" lookup main 2>/dev/null || true
  "$IP" -6 rule del priority "$((PRIORITY - 1))" fwmark "$MARK" lookup main 2>/dev/null || true
  "$IP" route del default dev "$TUN" table "$TABLE" 2>/dev/null || true
  "$IP" -6 route del default dev "$TUN" table "$TABLE" 2>/dev/null || true
}

recover_stale_rahvpn_routes() {
  local v4_routes v6_routes v4_rules v6_rules line priority
  v4_routes=$("$IP" route show table "$TABLE")
  v6_routes=$("$IP" -6 route show table "$TABLE")
  v4_rules=$("$IP" rule show)
  v6_rules=$("$IP" -6 rule show)

  # Recover only the exact rules/routes this helper installs. A table or rule
  # ID containing anything else may belong to another network manager.
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" =~ ^default[[:space:]]+dev[[:space:]]+rah0([[:space:]]+scope[[:space:]]+link)?[[:space:]]*$ ]] || return 1
  done <<< "$v4_routes"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" =~ ^default[[:space:]]+dev[[:space:]]+rah0([[:space:]]+scope[[:space:]]+link|[[:space:]]+metric[[:space:]]+1024[[:space:]]+pref[[:space:]]+medium)?[[:space:]]*$ ]] || return 1
  done <<< "$v6_routes"

  for priority in "$((PRIORITY - 1))" "$PRIORITY"; do
    while IFS= read -r line; do
      [[ "$line" == "$priority:"* ]] || continue
      if [ "$priority" -eq "$((PRIORITY - 1))" ]; then
        [[ "$line" =~ ^${priority}:[[:space:]]+from[[:space:]]+all[[:space:]]+fwmark[[:space:]]+(0x71b|1819)(/0xffffffff)?[[:space:]]+lookup[[:space:]]+main[[:space:]]*$ ]] || return 1
      else
        [[ "$line" =~ ^${priority}:[[:space:]]+from[[:space:]]+all[[:space:]]+lookup[[:space:]]+${TABLE}[[:space:]]*$ ]] || return 1
      fi
    done <<< "$v4_rules"
    while IFS= read -r line; do
      [[ "$line" == "$priority:"* ]] || continue
      if [ "$priority" -eq "$((PRIORITY - 1))" ]; then
        [[ "$line" =~ ^${priority}:[[:space:]]+from[[:space:]]+all[[:space:]]+fwmark[[:space:]]+(0x71b|1819)(/0xffffffff)?[[:space:]]+lookup[[:space:]]+main[[:space:]]*$ ]] || return 1
      else
        [[ "$line" =~ ^${priority}:[[:space:]]+from[[:space:]]+all[[:space:]]+lookup[[:space:]]+${TABLE}[[:space:]]*$ ]] || return 1
      fi
    done <<< "$v6_rules"
  done

  down
}

show_conflicts() {
  echo "IPv4 routes in table $TABLE:" >&2
  "$IP" route show table "$TABLE" >&2 || true
  echo "IPv6 routes in table $TABLE:" >&2
  "$IP" -6 route show table "$TABLE" >&2 || true
  echo "IPv4 rules at priorities $((PRIORITY - 1)) and $PRIORITY:" >&2
  "$IP" rule show | grep -E "^($((PRIORITY - 1))|$PRIORITY):" >&2 || true
  echo "IPv6 rules at priorities $((PRIORITY - 1)) and $PRIORITY:" >&2
  "$IP" -6 rule show | grep -E "^($((PRIORITY - 1))|$PRIORITY):" >&2 || true
}

conflicts_present() {
  [ -n "$("$IP" route show table "$TABLE")" ] || \
    [ -n "$("$IP" -6 route show table "$TABLE")" ] || \
    "$IP" rule show | grep -q "^$((PRIORITY - 1)):" || \
    "$IP" rule show | grep -q "^$PRIORITY:" || \
    "$IP" -6 rule show | grep -q "^$((PRIORITY - 1)):" || \
    "$IP" -6 rule show | grep -q "^$PRIORITY:"
}

recover() {
  if conflicts_present; then
    if recover_stale_rahvpn_routes; then
      echo "[+] removed stale RahVPN policy routes from the previous session" >&2
    else
      echo "RahVPN policy route IDs are already in use; refusing to overwrite them." >&2
      show_conflicts
      return 1
    fi
  fi
}

case "${1:-}" in
  recover)
    recover
    ;;
  start)
    recover
    # Roll back partially installed rules if either address family fails.
    trap down ERR
    "$IP" route replace default dev "$TUN" table "$TABLE"
    "$IP" -6 route replace default dev "$TUN" table "$TABLE"
    # Marked Aether and tun2socks sockets keep using the physical default route.
    "$IP" rule add priority "$((PRIORITY - 1))" fwmark "$MARK" lookup main
    "$IP" -6 rule add priority "$((PRIORITY - 1))" fwmark "$MARK" lookup main
    "$IP" rule add priority "$PRIORITY" lookup "$TABLE"
    "$IP" -6 rule add priority "$PRIORITY" lookup "$TABLE"
    trap - ERR
    ;;
  stop)
    down
    ;;
  *)
    echo "usage: $0 {start|stop}" >&2
    exit 2
    ;;
esac
