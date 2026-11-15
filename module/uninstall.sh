#!/system/bin/sh
# Runs when the module is removed: stop helpers and delete generated files.
DATA_DIR=/data/local/tmp

pkill -f 'dsh-root-bridge/[w]atch.sh' 2>/dev/null
pkill -f 'dsh-root-bridge/[t]haw.sh' 2>/dev/null
pkill -f dsh-rootd-conn.sh 2>/dev/null

rm -f "$DATA_DIR/dsh-rootd-conn.sh"
rm -f "$DATA_DIR/dsh-rootd.log"
rm -f "$DATA_DIR/dsh-thaw.log"

for base in /data/user/0 /data/data; do
  f="$base/io.github.ccch1mneyyy.dsh_app/files/runtime/rootfs/usr/local/bin/dsh-root"
  [ -f "$f" ] && rm -f "$f"
done

echo "dsh-root-bridge: removed"
