#!/bin/sh
# 把 module/ 打包成 KernelSU 可安装的 dist/dsh-root-bridge-v<version>.zip
set -e
cd "$(dirname "$0")"

VER=$(sed -n 's/^version=//p' module/module.prop | head -n 1)
OUT="dist/dsh-root-bridge-v$VER.zip"
mkdir -p dist
rm -f "$OUT"

python3 - "$OUT" <<'PY'
import os, sys, zipfile

out = sys.argv[1]
root = "module"
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for name in sorted(os.listdir(root)):
        if name.startswith(".") or name == "__pycache__":
            continue
        path = os.path.join(root, name)
        if not os.path.isfile(path):
            continue
        info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        mode = 0o755 if (name.endswith(".sh") or name == "dsh-root") else 0o644
        info.external_attr = mode << 16
        z.writestr(info, open(path, "rb").read())
print("files:", zipfile.ZipFile(out).namelist())
PY

echo "built $OUT"
