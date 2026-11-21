#!/system/bin/sh
# ColorOS thaw helper: when the system freezes an app's cgroup (速冻), write 0
# back. Runs as real root outside the app process tree.
#
# Interval is a trade-off: 5s is snappy but wakes the CPU often; 30s costs much
# less and a frozen app is still thawed within half a minute.
# Configure in /data/adb/dsh-root-bridge.conf:
#   THAW_APPS="pkg1 pkg2"    apps to watch (default: DSH Go only)
#   THAW_INTERVAL=30         seconds between checks (0 disables polling)
#   THAW_ENABLE=0            turn the helper off
export PATH=/system/bin:/system/xbin:/product/bin
LOG=/data/local/tmp/dsh-thaw.log
MAXLOG=${DSH_THAW_MAXLOG:-200}
CGROUP_ROOT=/sys/fs/cgroup/apps

CONF=/data/adb/dsh-root-bridge.conf
APPS=io.github.ccch1mneyyy.dsh_app
INTERVAL=${DSH_THAW_INTERVAL:-30}
[ -f "$CONF" ] && . "$CONF"
[ -n "$THAW_APPS" ] && APPS="$THAW_APPS"
[ -n "$THAW_INTERVAL" ] && INTERVAL="$THAW_INTERVAL"

log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"
  n=$(wc -l < "$LOG" 2>/dev/null)
  if [ -n "$n" ] && [ "$n" -gt "$MAXLOG" ]; then
    tail -n $((MAXLOG / 2)) "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
  fi
}

uid_of() {
  ls -ldn "/data/data/$1" 2>/dev/null | awk '{print $3}'
}

resolve_apps() {
  APPUIDS=""
  for pkg in $APPS; do
    u=$(uid_of "$pkg")
    [ -n "$u" ] && APPUIDS="$APPUIDS uid_$u"
  done
  if [ -n "$DSH_THAW_UIDS" ]; then APPUIDS="$DSH_THAW_UIDS"; fi
}

if [ "$THAW_ENABLE" = "0" ]; then
  log "thaw helper disabled by THAW_ENABLE=0"
  exit 0
fi

resolve_apps
log "watchdog start pid $$ (apps:$APPUIDS, every ${INTERVAL}s)"

while true; do
  if [ "$INTERVAL" = "0" ]; then
    log "thaw interval is 0; helper stopping"
    exit 0
  fi
  sleep "$INTERVAL"
  # 开机早于解锁时 /data/data 还读不到，uid 会解析为空：之后再试
  if [ -z "$APPUIDS" ]; then
    resolve_apps
    [ -n "$APPUIDS" ] && log "apps resolved:$APPUIDS"
  fi
  for u in $APPUIDS; do
    uiddir="$CGROUP_ROOT/$u"
    [ -d "$uiddir" ] || continue
    # 用 shell 内建 read 读，避免每次轮询都 fork 子进程
    for d in "$uiddir"/pid_*; do
      [ -d "$d" ] || continue
      fz=
      read -r fz < "$d/cgroup.freeze" 2>/dev/null || continue
      if [ "$fz" = "1" ]; then
        echo 0 > "$d/cgroup.freeze" 2>/dev/null
        now=
        read -r now < "$d/cgroup.freeze" 2>/dev/null
        log "thaw $u/${d##*/} frozen->$now"
      fi
    done
    uf=
    read -r uf < "$uiddir/cgroup.freeze" 2>/dev/null
    if [ "$uf" = "1" ]; then
      echo 0 > "$uiddir/cgroup.freeze" 2>/dev/null
      log "thaw $u cgroup"
    fi
  done
done
