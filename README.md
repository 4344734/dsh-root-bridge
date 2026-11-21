# DSH Root Bridge

给 DSH（尤其 [DSH Go](https://github.com/ccch1mneyyy/dsh-Go) 手机 App）的 proot 容器开一条**真正的 root 命令通道**。

> 非官方项目，与 DSH / DSH Go 作者无关；装模块就是在自己手机上开常驻 root 服务，风险自担。

## 两个部分

| 部分 | 是什么 | 从哪装 |
|---|---|---|
| **KernelSU 模块** | 在容器外起 `127.0.0.1:47913` 的 root 命令桥；容器里给一个 `dsh-root` 命令 | GitHub [Releases](../../releases) |
| **DSH 插件**（npm: `dsh-root-bridge`） | 给模型一个 `root_exec` 工具，走同一个桥 | DSH Go 插件市场 / npm |

先装模块（提供能力），再装插件（给模型用）。

## 为什么需要

DSH Go 的本机引擎跑在 proot 里，容器里的 `uid=0` 是假 root：`su` 执行不了，
读不到其他 App 的数据，也不能 `mount`、改系统文件。

模块在容器外起一个只监听 `127.0.0.1` 的命令服务（token 校验），
容器里的 `dsh-root`（以及插件里的 `root_exec` 工具）连过去，
命令就以真正的 root 在 Android 侧执行，输出和退出码原样带回。

## 特性

- 真 root：文件读写、`/proc`、`/sys`、`iptables`、`setenforce`、`screencap`、`dumpsys` 等
- 自愈：桥进程被杀立即重拉；App 更新把容器里的 `dsh-root` 删掉或换旧会立刻补回（事件驱动，平时零轮询）
- 流式输出、超时、换 uid、文件上传下载、后台任务

## 安装模块

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

## 安装插件

- DSH Go：设置 › 插件 › 插件市场，搜 `dsh-root-bridge`，装到当前主机
- 电脑上的 DSH：`npm i dsh-root-bridge`，或用插件管理器从 npm 安装

装好后模型会多一个 `root_exec` 工具：

```text
root_exec({ command: "id -u" })  →  exit 0, 输出 0
```

## 用法（dsh-root 命令）

```sh
dsh-root 'id'                       # 真 root
dsh-root 'ls /data/data | head'
echo 'df -h /data' | dsh-root

dsh-root --stream 'logcat -v time'  # 边跑边出
dsh-root --timeout 30 '<命令>'      # 超时强杀（rc=124）
dsh-root --as 2000 '<命令>'         # 换 uid

dsh-root --put 本地 /sdcard/x       # 上传
dsh-root --get /sdcard/x 本地       # 下载

dsh-root --bg '长任务'              # 后台任务
dsh-root --jobs / --job <id> / --kill <id>
```

## 已知限制

`pm` / `am` / `settings` / `input` / `wm` 这类 Android 框架命令会报
`Failed transaction (2147483646)`：ColorOS 等系统的 binder 限制，root 域和 shell 域都绕不过。
文件、系统、`dumpsys`、`screencap`、`iptables`、`/proc`、`/sys` 都正常。
需要操作界面的话，用 DSH Go 自带的手机操控（走 Shizuku）。

## 省电设计

- 桥挂掉：监督进程立即重拉，健康时零唤醒
- 容器客户端：开机检查一次 + `inotifyd` 文件事件补回，不轮询
- 空闲时没有周期任务（v1.5 里的解冻助手已在 v1.6 移除）

## 安全

- root 桥只绑定 `127.0.0.1`，不对外网开放
- token 在 App 私有目录 `~/.dsh/rootd/token`；**token 泄露 = 这台机器的 root 泄露**
- 只在你自己信任的设备上用；不需要时在 KernelSU 里禁用/卸载模块

## 仓库结构

```
module/    KernelSU 模块源文件（打包成 dist/*.zip）
plugin/    DSH 插件（发布到 npm）
market/    插件市场仓库要求的条目（提 PR 用）
dist/      打包好的模块 zip
build.sh   从 module/ 重新打包
```

## 自己构建

```sh
sh build.sh                                  # 生成 dist/dsh-root-bridge-v<version>.zip
cd plugin && npm pack                        # 检查插件 tarball
```

## License

[MIT](LICENSE)

---

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
