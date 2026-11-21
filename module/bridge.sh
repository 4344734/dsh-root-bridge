#!/system/bin/sh
# Root bridge supervisor: runs the listener in the foreground and restarts it
# when it exits. While the bridge is healthy this process sleeps in wait(),
# so there is no periodic wake-up.
export PATH=/system/bin:/system/xbin:/product/bin
MODDIR=${0%/*}
. "$MODDIR/lib.sh"

PORT=${DSH_ROOT_PORT:-47913}
PAYLOAD=/data/local/tmp/dsh-rootd-conn.sh

ensure_payload() {
  if [ ! -s "$PAYLOAD" ] || ! same "$PAYLOAD" "$MODDIR/conn.sh"; then
    cp "$MODDIR/conn.sh" "$PAYLOAD" 2>>"$LOG" && chmod 755 "$PAYLOAD" && log "payload refreshed"
  fi
}

ensure_payload
log "bridge supervisor start pid $$ (port $PORT)"

while :; do
  /system/bin/sh -c "exec /system/bin/toybox nc -L -s 127.0.0.1 -p $PORT /system/bin/sh $PAYLOAD" 2>>"$LOG"
  rc=$?
  log "bridge exited rc=$rc"
  if pgrep -f "nc -L -s 127.0.0.1 -p $PORT" >/dev/null 2>&1; then
    log "another listener is alive; supervisor exiting"
    exit 0
  fi
  sleep 2
done
