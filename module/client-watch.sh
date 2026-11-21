#!/system/bin/sh
# Keeps the container-side dsh-root present and current.
# One check at start, then filesystem events (inotifyd) — no polling.
export PATH=/system/bin:/system/xbin:/product/bin
MODDIR=${0%/*}
. "$MODDIR/lib.sh"

HANDLER=/data/local/tmp/dsh-client-event.sh

write_handler() {
  {
    echo '#!/system/bin/sh'
    echo "MODDIR='$MODDIR'"
    echo '. "$MODDIR/lib.sh"'
    echo 'ensure_client'
  } > "$HANDLER"
  chmod 755 "$HANDLER"
}

write_handler
log "client watchdog start pid $$ (event driven)"

while :; do
  ROOTFS=$(find_rootfs)
  if [ -z "$ROOTFS" ]; then
    log "rootfs not found yet; retrying in 30s"
    sleep 30
    continue
  fi
  ensure_client
  BINDIR="$ROOTFS/usr/local/bin"
  mkdir -p "$BINDIR" 2>/dev/null
  # n/d: a file in usr/local/bin was created or deleted
  # D/M: the rootfs directory itself was deleted or moved (runtime replacement)
  /system/bin/inotifyd "$HANDLER" "$BINDIR:nd" "$ROOTFS:DM" 2>>"$LOG"
  log "filesystem watch ended; restarting"
  sleep 2
done
