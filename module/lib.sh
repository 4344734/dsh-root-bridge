#!/system/bin/sh
# Shared helpers for the dsh-root-bridge module. Sourced, not executed.
# Caller must set MODDIR (module directory) before sourcing.

LOG=${DSH_ROOT_LOG:-/data/local/tmp/dsh-rootd.log}
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

# Copy the container-side client when it is missing or not the module's version.
ensure_client() {
  ROOTFS=$(find_rootfs)
  if [ -z "$ROOTFS" ]; then
    log "container rootfs not found; client not checked"
    return 1
  fi
  T="$ROOTFS/$CLIENT"
  if [ ! -s "$T" ] || ! same "$T" "$MODDIR/dsh-root"; then
    mkdir -p "$ROOTFS/usr/local/bin" 2>/dev/null
    if cp "$MODDIR/dsh-root" "$T" 2>/dev/null && chmod 755 "$T" 2>/dev/null; then
      log "client installed ($T)"
      return 0
    fi
    log "client install FAILED ($T)"
    return 1
  fi
  return 0
}
