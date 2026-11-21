# DSH Go Root Bridge

给 [DSH Go](https://github.com/ccch1mneyyy/dsh-Go) 手机 App 的 Linux 容器开一条**真正的 root 命令通道**的 KernelSU 模块。

> 非官方项目，与 DSH Go 作者无关；装模块就是在自己手机上开常驻 root 服务，风险自担。

## 为什么需要

DSH Go 的本机引擎跑在 proot 里，容器里的 `uid=0` 是假 root：`su` 执行不了，读不到其他 App 的数据，也不能 `mount`、改系统文件。

这个模块在容器外起一个只监听 `127.0.0.1` 的命令服务（token 校验），容器里的 `dsh-root` 连过去，命令就以真正的 root 在系统侧执行，输出和退出码原样带回。

## 特性

- 真 root：文件读写、`/proc`、`/sys`、`iptables`、`setenforce`、`screencap`、`dumpsys` 等
- 自愈：桥进程被杀 15 秒内自动重拉；App 更新把容器里的 `dsh-root` 删掉或换旧会自动补回
- 流式输出、超时、换 uid、文件上传下载、后台任务
- 可选 ColorOS 速冻解冻助手（默认只看 DSH Go）

## 要求

- DSH Go（本机引擎，proot 模式）
- KernelSU（已验证；Magisk 未测试）
- 手机已 root

## 安装

1. 到 [Releases](../../releases) 下载最新的 `dsh-root-bridge-vX.Y.zip`
2. KernelSU → 模块 → 右下角 `+` → 选择这个 zip
3. 重启手机
4. DSH Go 里验证：

```sh
dsh-root --status
# dsh-root: 桥正常（127.0.0.1:47913）
dsh-root 'id'
# uid=0(root) gid=0(root) context=u:r:ksu:s0
```

## 用法

```sh
dsh-root 'id'                       # 真 root
dsh-root 'ls /data/data | head'     # 读其他 App 的数据
echo 'df -h /data' | dsh-root       # 从 stdin 传命令

dsh-root --stream 'logcat -v time'  # 边跑边出
dsh-root --timeout 30 '<命令>'      # 30 秒后强杀（退出码 124）
dsh-root --as 2000 '<命令>'         # 换成别的 uid 跑

dsh-root --put 本地文件 /sdcard/x   # 上传
dsh-root --get /sdcard/x 本地文件   # 下载；省略本地文件就打到 stdout

dsh-root --bg '长任务'              # 后台任务，返回任务号
dsh-root --jobs                     # 列任务
dsh-root --job j123456 80           # 看日志最后 80 行
dsh-root --kill j123456             # 结束任务
```

## 已知限制

`pm` / `am` / `settings` / `input` / `wm` 这类 Android 框架命令会报：

```
cmd: Failure calling service package: Failed transaction (2147483646)
```

这是 ColorOS 等系统的 binder 限制，root 域和 shell 域都绕不过，不是模块的问题。
文件、系统、`dumpsys`、`screencap`、`iptables`、`/proc`、`/sys` 都正常。
需要操作界面的话，用 DSH Go 自带的手机操控（走 Shizuku）。

## 自愈机制（事件驱动，平时不轮询）

- 桥进程被杀：父进程立即重拉（`bridge.sh` 里 `wait`，健康时零唤醒）
- App 更新把 `/usr/local/bin/dsh-root` 删掉或换成旧版：`inotifyd` 监听文件事件，立刻补回
- 开机时检查一次；rootfs 被整体替换也会触发事件重新检查
- 空闲唤醒实测：`bridge.sh` 0 次/分、`client-watch.sh` 0 次/分、
  `thaw.sh`（30 秒）2 次/分；旧版（15 秒轮询 + 5 秒解冻）是 156 次/分

## 解冻助手（可选）

ColorOS 会冻结后台 App。默认每 30 秒检查一次（旧版是 5 秒）；可以按需关掉或调整：

```sh
# /data/adb/dsh-root-bridge.conf
THAW_ENABLE=0            # 完全关掉
THAW_INTERVAL=60         # 或放慢到 60 秒
THAW_APPS="io.github.ccch1mneyyy.dsh_app com.example.other"
```

## 安全

- 服务只绑定 `127.0.0.1`，不对外网开放
- token 在 App 私有目录 `~/.dsh/rootd/token`，其他普通 App 读不到
- **token 泄露 = root 泄露**：不要分享 token 或整个 `~/.dsh`
- 不需要时在 KernelSU 里禁用/卸载模块

## 仓库结构

```
module/    模块源文件（KernelSU 模块根目录内容）
dist/      打包好的可安装 zip
build.sh   从 module/ 重新打包到 dist/
```

## 自己构建

```sh
sh build.sh
```

会生成 `dist/dsh-root-bridge-v<version>.zip`（版本号取自 `module/module.prop`）。

## 卸载

KernelSU → 模块 → 卸载。模块自带的 `uninstall.sh` 会清理临时文件和容器里的客户端。

## License

[MIT](LICENSE)（发布前把版权人改成你自己）

---

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
