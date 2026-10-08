#!/usr/bin/env bash
# One polkit-authorized session owns Aether, tun2socks, and system routes.
set -euo pipefail

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
SUPERVISOR_PATH=$(readlink -f "$0")

if [ "$(id -u)" -ne 0 ]; then
  echo "This helper must be started by pkexec." >&2
  exit 1
fi

RUN_UID=
RUN_GID=
RUN_USER=
CORE=
TUN2SOCKS=
TUN_CONFIG=
ROUTES=
STATE_DIR=
declare -a AETHER_ENV=()

while (($#)); do
  case "$1" in
    --uid) RUN_UID="$2"; shift 2 ;;
    --gid) RUN_GID="$2"; shift 2 ;;
    --user) RUN_USER="$2"; shift 2 ;;
    --core) CORE="$2"; shift 2 ;;
    --tun2socks) TUN2SOCKS="$2"; shift 2 ;;
    --tun-config) TUN_CONFIG="$2"; shift 2 ;;
    --routes) ROUTES="$2"; shift 2 ;;
    --state-dir) STATE_DIR="$2"; shift 2 ;;
    --env) AETHER_ENV+=("$2"); shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ "$RUN_UID" =~ ^[0-9]+$ && "$RUN_GID" =~ ^[0-9]+$ ]] || {
  echo "invalid user or group ID" >&2; exit 2;
}
[[ "$RUN_USER" =~ ^[a-zA-Z0-9_.-]+$ ]] || {
  echo "invalid username" >&2; exit 2;
}
for path in "$CORE" "$TUN2SOCKS" "$TUN_CONFIG" "$ROUTES" "$STATE_DIR"; do
  [ -e "$path" ] || { echo "required TUN file not found: $path" >&2; exit 1; }
done
[ -x "$CORE" ] && [ -x "$TUN2SOCKS" ] && [ -x "$ROUTES" ] || {
  echo "Aether, hev-socks5-tunnel, and the route helper must be executable" >&2
  exit 1
}
[ -c /dev/net/tun ] || { echo "/dev/net/tun is unavailable" >&2; exit 1; }
for value in "${AETHER_ENV[@]}"; do
  [[ "$value" =~ ^(AETHER_[A-Z0-9_]+|HOME|PATH|LANG)=.*$ ]] || {
    echo "invalid Aether environment entry" >&2; exit 2;
  }
done

declare -a CORE_ENV=("${AETHER_ENV[@]}")
declare -a TUN_ENV=("HOME=$STATE_DIR" "PATH=$PATH" "LANG=${LANG:-C.UTF-8}")
CORE_PID=
TUN_PID=
ROUTES_UP=0
STOP_WATCHER_PID=
RESOLVER_CONFIGURED=0
PSIPHON_TUN=0
RESOLVECTL=
IPTABLES=
IP6TABLES=
PSIPHON_MARK=1819
CGROUP_DIR=
CGROUP_PATH=
MARK_RULE_V4=0
MARK_RULE_V6=0
for value in "${AETHER_ENV[@]}"; do
  if [ "$value" = "AETHER_PSIPHON=only" ]; then PSIPHON_TUN=1; fi
done
RESOLVECTL=$(command -v resolvectl || true)
if [ "$PSIPHON_TUN" -eq 1 ]; then
  [ -n "$RESOLVECTL" ] || {
    echo "Psiphon TUN requires systemd-resolved (resolvectl) to route DNS through mapdns." >&2
    exit 1
  }
  IPTABLES=$(command -v iptables || true)
  IP6TABLES=$(command -v ip6tables || true)
  [ -n "$IPTABLES" ] && [ -n "$IP6TABLES" ] && [ -f /sys/fs/cgroup/cgroup.procs ] || {
    echo "Psiphon TUN requires cgroup v2 plus iptables and ip6tables cgroup matching." >&2
    exit 1
  }
fi

watch_stop_request() {
  local supervisor_pid=$$
  (
    while kill -0 "$supervisor_pid" 2>/dev/null; do
      if [ -f "$STATE_DIR/rahvpn-stop-request" ]; then
        rm -f "$STATE_DIR/rahvpn-stop-request"
        echo "[*] stop requested by RahVPN; shutting down the TUN session" >&2
        kill -TERM "$supervisor_pid" 2>/dev/null || true
        exit 0
      fi
      sleep 0.1
    done
  ) 9>&- &
  STOP_WATCHER_PID=$!
}

start_as_user() {
  # Keep neither supervisor lock in children.
  exec 8>&-
  exec 9>&-
  exec setpriv \
    --reuid="$RUN_UID" \
    --regid="$RUN_GID" \
    --init-groups \
    --inh-caps=+net_admin \
    --ambient-caps=+net_admin \
    -- /bin/sh -c \
    'cd -- "$1" || { echo "cannot access RahVPN state directory as the app user: $1" >&2; exit 1; }; shift; exec /usr/bin/env "$@"' \
    rahvpn "$STATE_DIR" "$@"
}

proc_parent_pid() {
  local stat rest state parent
  { IFS= read -r stat < "/proc/$1/stat"; } 2>/dev/null || return 1
  rest=${stat##*) }
  read -r state parent _ <<< "$rest"
  [[ "$parent" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$parent"
}

is_related_process() {
  local candidate="$1" cursor parent depth

  # Exclude this supervisor, its children (including process substitutions),
  # and pkexec/shell parents. A forked Bash child inherits the same argv.
  cursor=$candidate
  for ((depth = 0; depth < 128 && cursor > 1; depth++)); do
    [ "$cursor" = "$$" ] && return 0
    parent=$(proc_parent_pid "$cursor") || break
    cursor=$parent
  done

  cursor=$$
  for ((depth = 0; depth < 128 && cursor > 1; depth++)); do
    [ "$cursor" = "$candidate" ] && return 0
    parent=$(proc_parent_pid "$cursor") || break
    cursor=$parent
  done
  return 1
}

active_supervisor_pids() {
  local proc cmdline pid exe
  for proc in /proc/[0-9]*; do
    pid=${proc##*/}
    exe=$(readlink "$proc/exe" 2>/dev/null) || continue
    exe=${exe% (deleted)}
    case "${exe##*/}" in bash|sh) ;; *) continue ;; esac
    { cmdline=$(tr '\0' '\n' < "$proc/cmdline"); } 2>/dev/null || continue
    if grep -Fxq -- "$SUPERVISOR_PATH" <<< "$cmdline" &&
       grep -Fxq -- "$TUN2SOCKS" <<< "$cmdline" &&
       grep -Fxq -- "$TUN_CONFIG" <<< "$cmdline"; then
      is_related_process "$pid" && continue
      printf '%s\n' "$pid"
    fi
  done
  return 0
}

stop_previous_supervisors() {
  local pid i still_running round
  local -a previous=()
  echo "[*] checking for unfinished RahVPN TUN sessions" >&2
  for ((round = 0; round < 3; round++)); do
    mapfile -t previous < <(active_supervisor_pids)
    if ((${#previous[@]} == 0)); then
      echo "[+] no previous RahVPN supervisor remains" >&2
      return 0
    fi
    echo "[*] stopping ${#previous[@]} previous supervisor process(es), pass $((round + 1))/3" >&2
    for pid in "${previous[@]}"; do
      echo "[+] stopping previous RahVPN supervisor $pid" >&2
      kill -TERM "$pid" 2>/dev/null || true
    done
    for pid in "${previous[@]}"; do
      still_running=1
      for ((i = 0; i < 80; i++)); do
        if ! kill -0 "$pid" 2>/dev/null; then
          still_running=0
          echo "[+] previous supervisor $pid exited and cleaned up" >&2
          break
        fi
        sleep 0.1
      done
      if [ "$still_running" -eq 1 ]; then
        echo "previous RahVPN supervisor $pid did not stop cleanly; refusing to replace its tunnel." >&2
        return 1
      fi
    done
  done
  mapfile -t previous < <(active_supervisor_pids)
  if ((${#previous[@]})); then
    echo "RahVPN supervisor processes are still active: ${previous[*]}" >&2
    return 1
  fi
}

remove_orphan_tun() {
  local proc exe cmdline owner state i
  local -a owners=()
  if ! ip link show rah0 >/dev/null 2>&1; then return 0; fi

  for proc in /proc/[0-9]*; do
    exe=$(readlink "$proc/exe" 2>/dev/null) || continue
    exe=${exe% (deleted)}
    [ "${exe##*/}" = hev-socks5-tunnel ] || continue
    { cmdline=$(tr '\0' '\n' < "$proc/cmdline"); } 2>/dev/null || continue
    if [ "$exe" = "$TUN2SOCKS" ] && grep -Fxq -- "$TUN_CONFIG" <<< "$cmdline"; then
      owners+=("${proc##*/}")
    else
      echo "TUN interface rah0 is held by another hev-socks5-tunnel process (pid ${proc##*/}); refusing to stop it." >&2
      ip -details link show rah0 >&2 || true
      return 1
    fi
  done

  for owner in "${owners[@]}"; do
    echo "[+] stopping orphaned RahVPN tun2socks process $owner" >&2
    kill -TERM "$owner" 2>/dev/null || true
  done
  for owner in "${owners[@]}"; do
    for ((i = 0; i < 30; i++)); do
      [ -e "/proc/$owner/exe" ] || break
      state=$(ps -o stat= -p "$owner" 2>/dev/null || true)
      [[ "$state" == Z* ]] && break
      sleep 0.1
    done
    if [ -e "/proc/$owner/exe" ] && [[ "$(ps -o stat= -p "$owner" 2>/dev/null || true)" != Z* ]]; then
      echo "[!] tun2socks process $owner did not stop; sending SIGKILL" >&2
      kill -KILL "$owner" 2>/dev/null || true
    fi
  done

  echo "[+] removing orphaned RahVPN TUN interface rah0" >&2
  if ip link show rah0 >/dev/null 2>&1; then
    if ! ip link delete rah0; then
      # hev-socks5-tunnel can remove its nonpersistent TUN as it exits.
      if ip link show rah0 >/dev/null 2>&1; then
        echo "could not remove orphaned TUN interface rah0" >&2
        return 1
      fi
    fi
  fi
  echo "[+] orphaned TUN interface cleanup complete" >&2
}

stop_orphan_core() {
  local proc exe env owner i state
  local -a owners=()
  for proc in /proc/[0-9]*; do
    exe=$(readlink "$proc/exe" 2>/dev/null) || continue
    exe=${exe% (deleted)}
    [ "$exe" = "$CORE" ] || continue
    { env=$(tr '\0' '\n' < "$proc/environ"); } 2>/dev/null || continue
    if grep -Fxq -- "AETHER_CONFIG=$STATE_DIR/aether.toml" <<< "$env" &&
       grep -Fxq -- 'AETHER_SOCKS=127.0.0.1:1819' <<< "$env"; then
      owners+=("${proc##*/}")
    fi
  done
  for owner in "${owners[@]}"; do
    echo "[+] stopping leftover RahVPN Aether core $owner" >&2
    kill -TERM "$owner" 2>/dev/null || true
  done
  for owner in "${owners[@]}"; do
    for ((i = 0; i < 30; i++)); do
      [ -e "/proc/$owner/exe" ] || break
      state=$(ps -o stat= -p "$owner" 2>/dev/null || true)
      [[ "$state" == Z* ]] && break
      sleep 0.1
    done
    if [ -e "/proc/$owner/exe" ] && [[ "$(ps -o stat= -p "$owner" 2>/dev/null || true)" != Z* ]]; then
      echo "[!] Aether core $owner did not stop; sending SIGKILL" >&2
      kill -KILL "$owner" 2>/dev/null || true
    fi
  done
}

stop_child() {
  local pid="$1" i state
  [ -n "$pid" ] || return 0
  kill -TERM "$pid" 2>/dev/null || true
  for ((i = 0; i < 30; i++)); do
    kill -0 "$pid" 2>/dev/null || break
    state=$(ps -o stat= -p "$pid" 2>/dev/null || true)
    [[ "$state" == Z* ]] && break
    sleep 0.1
  done
  if kill -0 "$pid" 2>/dev/null && [[ "$(ps -o stat= -p "$pid" 2>/dev/null || true)" != Z* ]]; then
    kill -KILL "$pid" 2>/dev/null || true
  fi
  wait "$pid" 2>/dev/null || true
}

stop_cgroup_processes() {
  local pid i remaining
  [ -n "$CGROUP_DIR" ] || return 0
  [ -d "$CGROUP_DIR" ] || return 0

  # Aether normally reaps Psiphon on SIGTERM. If it does not, the dedicated
  # cgroup is the exact process boundary for safely stopping any leftover.
  if [ -w "$CGROUP_DIR/cgroup.kill" ]; then
    printf '1\n' > "$CGROUP_DIR/cgroup.kill" || true
  else
    while read -r pid; do
      [[ "$pid" =~ ^[0-9]+$ ]] && kill -TERM "$pid" 2>/dev/null || true
    done < "$CGROUP_DIR/cgroup.procs"
  fi

  for ((i = 0; i < 30; i++)); do
    remaining=$(cat "$CGROUP_DIR/cgroup.procs" 2>/dev/null || true)
    [ -z "$remaining" ] && return 0
    sleep 0.1
  done
  while read -r pid; do
    [[ "$pid" =~ ^[0-9]+$ ]] && kill -KILL "$pid" 2>/dev/null || true
  done < "$CGROUP_DIR/cgroup.procs"
  for ((i = 0; i < 20; i++)); do
    remaining=$(cat "$CGROUP_DIR/cgroup.procs" 2>/dev/null || true)
    [ -z "$remaining" ] && return 0
    sleep 0.1
  done
  echo "warning: processes remain in Psiphon cgroup $CGROUP_PATH: ${remaining//$'\n'/ }" >&2
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM HUP
  if [ -n "$STOP_WATCHER_PID" ]; then
    kill -TERM "$STOP_WATCHER_PID" 2>/dev/null || true
    wait "$STOP_WATCHER_PID" 2>/dev/null || true
    STOP_WATCHER_PID=
  fi
  rm -f "$STATE_DIR/rahvpn-stop-request"
  if [ "$ROUTES_UP" -eq 1 ]; then
    "$ROUTES" stop || echo "warning: failed to restore original network routes" >&2
    ROUTES_UP=0
  fi
  if [ "$RESOLVER_CONFIGURED" -eq 1 ]; then
    "$RESOLVECTL" revert rah0 || echo "warning: failed to restore DNS settings for rah0" >&2
    RESOLVER_CONFIGURED=0
  fi
  rm -f "$STATE_DIR/rahvpn-psiphon-ready"
  if [ -n "$TUN_PID" ]; then
    stop_child "$TUN_PID"
    remove_orphan_tun || echo "warning: failed to remove RahVPN TUN interface" >&2
  fi
  if [ -n "$CORE_PID" ]; then
    stop_child "$CORE_PID"
  fi
  if ! stop_cgroup_processes; then
    echo "warning: Psiphon cgroup still has processes after cleanup" >&2
  fi
  if [ "$MARK_RULE_V4" -eq 1 ]; then
    "$IPTABLES" -w -t mangle -D OUTPUT -m cgroup --path "$CGROUP_PATH" -j MARK --set-mark "$PSIPHON_MARK" 2>/dev/null || true
    MARK_RULE_V4=0
  fi
  if [ "$MARK_RULE_V6" -eq 1 ]; then
    "$IP6TABLES" -w -t mangle -D OUTPUT -m cgroup --path "$CGROUP_PATH" -j MARK --set-mark "$PSIPHON_MARK" 2>/dev/null || true
    MARK_RULE_V6=0
  fi
  if [ -n "$CGROUP_DIR" ]; then
    rmdir "$CGROUP_DIR" 2>/dev/null || echo "warning: could not remove Psiphon cgroup $CGROUP_PATH" >&2
    CGROUP_DIR=
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
trap 'exit 129' HUP

watch_stop_request

# Serialize startup and stale-session cleanup, without making a live session's
# lock prevent a replacement attempt from stopping that session.
echo "[*] acquiring the RahVPN TUN startup lock" >&2
mkdir -p /run/lock
exec 8>/run/lock/rahvpn-tun-start.lock
flock -n 8 || {
  echo "another RahVPN TUN start is already being prepared; refusing a duplicate attempt." >&2
  exit 1
}
echo "[+] acquired the RahVPN TUN startup lock" >&2
# Complete stale-session cleanup before reusing the shared TUN name and routes.
stop_previous_supervisors

echo "[*] acquiring the RahVPN TUN session lock" >&2
exec 9>/run/lock/rahvpn-tun-supervisor.lock
flock -n 9 || {
  echo "another RahVPN TUN session acquired the system lock; refusing to start a duplicate." >&2
  exit 1
}
echo "[+] acquired the RahVPN TUN session lock" >&2
exec 8>&-
if [ "$PSIPHON_TUN" -eq 1 ]; then
  CGROUP_PATH="rahvpn-psiphon-$RUN_UID-$$"
  CGROUP_DIR="/sys/fs/cgroup/$CGROUP_PATH"
  mkdir "$CGROUP_DIR"
  "$IPTABLES" -w -t mangle -I OUTPUT 1 -m cgroup --path "$CGROUP_PATH" -j MARK --set-mark "$PSIPHON_MARK"
  MARK_RULE_V4=1
  "$IP6TABLES" -w -t mangle -I OUTPUT 1 -m cgroup --path "$CGROUP_PATH" -j MARK --set-mark "$PSIPHON_MARK"
  MARK_RULE_V6=1
  echo "[+] Psiphon egress will bypass rah0 via cgroup socket marking" >&2
fi
echo "[*] restoring stale RahVPN policy routes, if any" >&2
$ROUTES recover
echo "[*] stopping any leftover Aether core from this RahVPN profile" >&2
stop_orphan_core
echo "[*] checking for an orphaned TUN interface" >&2
remove_orphan_tun
echo "[*] starting Aether core" >&2
if [ "$PSIPHON_TUN" -eq 1 ]; then
  # Place the core in its own cgroup before it can spawn Psiphon. Psiphon is a
  # separate process and does not inherit Aether's per-socket SO_MARK setting.
  (
    kill -STOP "$BASHPID"
    start_as_user "${CORE_ENV[@]}" "$CORE"
  ) &
  CORE_PID=$!
  for ((i = 0; i < 50; i++)); do
    state=$(ps -o stat= -p "$CORE_PID" 2>/dev/null || true)
    [[ "$state" == T* ]] && break
    sleep 0.02
  done
  [[ "$(ps -o stat= -p "$CORE_PID" 2>/dev/null || true)" == T* ]] || {
    echo "could not pause Aether before assigning its Psiphon cgroup" >&2
    exit 1
  }
  if ! printf '%s\n' "$CORE_PID" > "$CGROUP_DIR/cgroup.procs"; then
    kill -CONT "$CORE_PID" 2>/dev/null || true
    echo "could not assign Aether and Psiphon to their egress-mark cgroup" >&2
    exit 1
  fi
  kill -CONT "$CORE_PID"
else
  start_as_user "${CORE_ENV[@]}" "$CORE" &
  CORE_PID=$!
fi

# Do not redirect the system routes until Aether has a working SOCKS listener.
if [ "$PSIPHON_TUN" -eq 1 ]; then
  echo "[*] waiting for Psiphon to establish its tunnel (Aether timeout: 180 seconds)" >&2
else
  echo "[*] waiting for Aether SOCKS5" >&2
fi
deadline=$((SECONDS + 600))
SOCKS_READY=0
last_wait_log=$SECONDS
while ((SECONDS < deadline)); do
  if ! kill -0 "$CORE_PID" 2>/dev/null; then
    set +e
    wait "$CORE_PID"
    status=$?
    set -e
    exit "$status"
  fi
  if [ "$PSIPHON_TUN" -eq 1 ]; then
    # Aether's readiness log confirms its SOCKS listener is open. Avoid a raw
    # TCP probe because Psiphon logs the incomplete SOCKS handshake as an error.
    if [ -f "$STATE_DIR/rahvpn-psiphon-ready" ]; then
      echo "[+] Psiphon is ready and Aether SOCKS5 is listening" >&2
      break
    elif ((SECONDS - last_wait_log >= 15)); then
      echo "[*] still waiting for Psiphon tunnel readiness (${SECONDS}s elapsed)" >&2
      last_wait_log=$SECONDS
    fi
  else
    if (exec 3<>/dev/tcp/127.0.0.1/1819) 2>/dev/null; then
      SOCKS_READY=1
      echo "[+] Aether SOCKS5 is listening" >&2
      break
    fi
  fi
  sleep 0.25
done
if ((SECONDS >= deadline)); then
  echo "timed out waiting for Aether SOCKS5 at 127.0.0.1:1819" >&2
  exit 1
fi

start_as_user "${TUN_ENV[@]}" "$TUN2SOCKS" "$TUN_CONFIG" &
TUN_PID=$!
deadline=$((SECONDS + 10))
while ((SECONDS < deadline)); do
  if ! kill -0 "$TUN_PID" 2>/dev/null; then
    set +e
    wait "$TUN_PID"
    status=$?
    set -e
    exit "$status"
  fi
  if ip link show rah0 >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done
if ! ip link show rah0 >/dev/null 2>&1; then
  echo "timed out waiting for TUN interface rah0" >&2
  exit 1
fi

"$ROUTES" start
ROUTES_UP=1
if [ -n "$RESOLVECTL" ]; then
  echo "[*] routing system DNS to TUN mapdns at 198.18.0.2" >&2
  RESOLVER_CONFIGURED=1
  "$RESOLVECTL" dns rah0 198.18.0.2
  "$RESOLVECTL" domain rah0 '~.'
elif [ "$PSIPHON_TUN" -eq 0 ]; then
  echo "[*] resolvectl unavailable; system DNS will use the existing resolver through rah0" >&2
fi
printf '%s\n' RAHVPN_TUN_READY

set +e
wait -n "$CORE_PID" "$TUN_PID"
status=$?
set -e
exit "$status"
