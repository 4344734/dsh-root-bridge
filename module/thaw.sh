#!/system/bin/sh
# Thaw watchdog: ColorOS may freeze app cgroups (速冻). Runs as real root
# outside the app process tree, so it keeps thawing the apps we care about.
export PATH=/system/bin:/system/xbin:/product/bin
LOG=/data/local/tmp/dsh-thaw.log
MAXLOG=${DSH_THAW_MAXLOG:-200}
CGROUP_ROOT=/sys/fs/cgroup/apps
INTERVAL=${DSH_THAW_INTERVAL:-5}

uid_of() {
  ls -ldn "/data/data/$1" 2>/dev/null | awk '{print $3}'
}

# 默认只看 DSH Go 自己；想多解冻几个 App，写 /data/adb/dsh-root-bridge.conf：
#   THAW_APPS="io.github.ccch1mneyyy.dsh_app cn.ppps.forwarder"
CONF=/data/adb/dsh-root-bridge.conf
APPS=io.github.ccch1mneyyy.dsh_app
if [ -f "$CONF" ]; then
  . "$CONF"
  [ -n "$THAW_APPS" ] && APPS="$THAW_APPS"
fi

resolve_apps() {
  APPUIDS=""
  for pkg in $APPS; do
    u=$(uid_of "$pkg")
    [ -n "$u" ] && APPUIDS="$APPUIDS uid_$u"
  done
  if [ -n "$DSH_THAW_UIDS" ]; then APPUIDS="$DSH_THAW_UIDS"; fi
}
resolve_apps

log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"
  n=$(wc -l < "$LOG" 2>/dev/null)
  if [ -n "$n" ] && [ "$n" -gt "$MAXLOG" ]; then
    tail -n $((MAXLOG / 2)) "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
  fi
}

log "watchdog start pid $$ (apps:$APPUIDS)"

while true; do
  sleep "$INTERVAL"
  # 开机早于解锁时 /data/data 还读不到，uid 会解析为空：之后再试
  if [ -z "$APPUIDS" ]; then
    resolve_apps
    [ -n "$APPUIDS" ] && log "apps resolved:$APPUIDS"
  fi
  for u in $APPUIDS; do
    uiddir="$CGROUP_ROOT/$u"
    [ -d "$uiddir" ] || continue
    for d in "$uiddir"/pid_*; do
      [ -d "$d" ] || continue
      fz=$(cat "$d/cgroup.freeze" 2>/dev/null)
      if [ "$fz" = "1" ]; then
        echo 0 > "$d/cgroup.freeze" 2>/dev/null
        now=$(cat "$d/cgroup.freeze" 2>/dev/null)
        log "thaw $u/${d##*/} frozen->$now"
      fi
    done
    uf=$(cat "$uiddir/cgroup.freeze" 2>/dev/null)
    if [ "$uf" = "1" ]; then
      echo 0 > "$uiddir/cgroup.freeze" 2>/dev/null
      log "thaw $u cgroup"
    fi
  done
done
