#!/system/bin/sh
# DSH Go Root Bridge — module service entry (KernelSU late_start).
# Starts the watchdog (bridge + container client) and the thaw helper.
export PATH=/system/bin:/system/xbin:/product/bin
MODDIR=${0%/*}
LOG=/data/local/tmp/dsh-rootd.log
echo "[$(date '+%m-%d %H:%M:%S')] boot start" >> "$LOG"

pkill -f 'dsh-root-bridge/[w]atch.sh' 2>/dev/null
pkill -f 'dsh-root-bridge/[t]haw.sh' 2>/dev/null
pkill -f dsh-rootd-conn.sh 2>/dev/null
sleep 1

setsid /system/bin/sh "$MODDIR/watch.sh" </dev/null >/dev/null 2>&1 &
echo "[$(date '+%m-%d %H:%M:%S')] watchdog pid $!" >> "$LOG"

setsid /system/bin/sh "$MODDIR/thaw.sh" </dev/null >/dev/null 2>&1 &
echo "[$(date '+%m-%d %H:%M:%S')] thaw helper pid $!" >> "$LOG"
