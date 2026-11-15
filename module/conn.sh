#!/system/bin/sh
# DSH Go root bridge — handles one connection, runs one command as root.
export PATH=/system/bin:/system/xbin:/product/bin:/vendor/bin

find_token() {
  if [ -n "$DSH_TOKEN_FILE" ]; then echo "$DSH_TOKEN_FILE"; return; fi
  for base in /data/user/0 /data/data; do
    f="$base/io.github.ccch1mneyyy.dsh_app/files/runtime/rootfs/root/.dsh/rootd/token"
    if [ -s "$f" ]; then echo "$f"; return; fi
  done
  ls /data/user/0/*/files/runtime/rootfs/root/.dsh/rootd/token 2>/dev/null | head -n 1
}

TOKEN_FILE=$(find_token)

IFS= read -r token || exit 1
expected=$(cat "$TOKEN_FILE" 2>/dev/null)
if [ -z "$expected" ] || [ "$token" != "$expected" ]; then
  echo "AUTH_FAIL"
  exit 1
fi

cmd=$(cat)
if [ -z "$cmd" ]; then
  echo "__RC__0"
  exit 0
fi

/system/bin/sh -c "$cmd" 2>&1
rc=$?
echo "__RC__$rc"
