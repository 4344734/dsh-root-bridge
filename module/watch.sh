#!/system/bin/sh
# DSH Go Root Bridge watchdog.
# Every INTERVAL seconds: restart the bridge if it died, and keep the
# container-side client present and identical to the module copy.
export PATH=/system/bin:/system/xbin:/product/bin
MODDIR=${0%/*}
PORT=${DSH_ROOT_PORT:-47913}
LOG=${DSH_ROOT_LOG:-/data/local/tmp/dsh-rootd.log}
INTERVAL=${DSH_ROOT_INTERVAL:-15}
PAYLOAD=/data/local/tmp/dsh-rootd-conn.sh
CLIENT=usr/local/bin/dsh-root

log() {
  echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"
  n=$(wc -l < "$LOG" 2>/dev/null)
  if [ -n "$n" ] && [ "$n" -gt 400 ]; then
    tail -n 200 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
  fi
}

find_rootfs() {
  if [ -n "$DSH_ROOT_ROOTFS" ]; then echo "$DSH_ROOT_ROOTFS"; return; fi
  for base in /data/user/0 /data/data; do
    d="$base/io.github.ccch1mneyyy.dsh_app/files/runtime/rootfs"
    if [ -d "$d" ]; then echo "$d"; return; fi
  done
  d=$(ls -d /data/user/0/*/files/runtime/rootfs 2>/dev/null | head -n 1)
  [ -n "$d" ] && echo "$d"
}

same() {
  a=$(md5sum "$1" 2>/dev/null | cut -d' ' -f1)
  b=$(md5sum "$2" 2>/dev/null | cut -d' ' -f1)
  [ -n "$a" ] && [ "$a" = "$b" ]
}

ensure_payload() {
  if [ ! -s "$PAYLOAD" ] || ! same "$PAYLOAD" "$MODDIR/conn.sh"; then
    cp "$MODDIR/conn.sh" "$PAYLOAD" 2>>"$LOG" && chmod 755 "$PAYLOAD" && log "payload refreshed"
  fi
}

bridge_alive() {
  pgrep -f "nc -L -s 127.0.0.1 -p $PORT" >/dev/null 2>&1
}

start_bridge() {
  ensure_payload
  pkill -f "nc -L -s 127.0.0.1 -p $PORT" 2>/dev/null
  sleep 1
  setsid /system/bin/toybox nc -L -s 127.0.0.1 -p "$PORT" /system/bin/sh "$PAYLOAD" </dev/null >/dev/null 2>&1 &
  sleep 1
  if bridge_alive; then
    log "bridge up on $PORT"
  else
    log "bridge FAILED to start on $PORT"
  fi
}

ensure_client() {
  ROOTFS=$(find_rootfs)
  if [ -z "$ROOTFS" ]; then
    log "container rootfs not found; client not checked"
    return
  fi
  T="$ROOTFS/$CLIENT"
  if [ ! -s "$T" ] || ! same "$T" "$MODDIR/dsh-root"; then
    mkdir -p "$ROOTFS/usr/local/bin" 2>/dev/null
    if cp "$MODDIR/dsh-root" "$T" 2>/dev/null && chmod 755 "$T" 2>/dev/null; then
      log "client installed ($T)"
    else
      log "client install FAILED ($T)"
    fi
  fi
}

log "watchdog start pid $$ (port $PORT, every ${INTERVAL}s)"
start_bridge
ensure_client
while true; do
  sleep "$INTERVAL"
  bridge_alive || start_bridge
  ensure_client
done
