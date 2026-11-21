#!/system/bin/sh
# DSH Go Root Bridge — module service entry (KernelSU late_start).
# Starts three helpers; none of them polls while things are healthy:
#   bridge.sh        keeps the root command listener up (restarts on exit)
#   client-watch.sh  restores the container client on startup + filesystem events
#   thaw.sh          optional ColorOS thaw helper (slow interval, configurable)
export PATH=/system/bin:/system/xbin:/product/bin
MODDIR=${0%/*}
. "$MODDIR/lib.sh"

log "boot start"

pkill -f 'dsh-root-bridge/[w]atch.sh' 2>/dev/null
pkill -f 'dsh-root-bridge/[b]ridge.sh' 2>/dev/null
pkill -f 'dsh-root-bridge/[c]lient-watch.sh' 2>/dev/null
pkill -f 'dsh-root-bridge/[t]haw.sh' 2>/dev/null
pkill -f dsh-rootd-conn.sh 2>/dev/null
sleep 1

setsid /system/bin/sh "$MODDIR/bridge.sh" </dev/null >/dev/null 2>&1 &
log "bridge supervisor pid $!"

setsid /system/bin/sh "$MODDIR/client-watch.sh" </dev/null >/dev/null 2>&1 &
log "client watchdog pid $!"

setsid /system/bin/sh "$MODDIR/thaw.sh" </dev/null >/dev/null 2>&1 &
log "thaw helper pid $!"
