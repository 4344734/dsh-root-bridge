# dsh-root-bridge（DSH 插件）

在 DSH 里以**真正的 root** 执行 Android 侧命令，绕开 proot 容器的假 root。

它给模型一个 `root_exec` 工具：命令通过本机回环上的 root 桥（`127.0.0.1:47913`，token 校验）
交给 Android 系统侧执行，输出和退出码原样返回。

> 这是 **DSH 插件**（装在 DSH 主机上的 npm 包）。真正的 root 能力来自配套的
> **KernelSU 模块** [`dsh-root-bridge`](https://github.com/<你的GitHub用户名>/dsh-root-bridge)，
> 先装模块、再装插件。

## 为什么需要

DSH Go 的本机引擎跑在 proot 里，容器里的 `uid=0` 是假 root：`su` 执行不了，
读不到其他 App 的数据，也不能 `mount`、改系统文件。
配套模块在容器外开一条 root 命令通道，这个插件把它接成一个模型可用的工具。

## 安装

1. **先装 KernelSU 模块**（提供 root 桥）：
   到 [Releases](https://github.com/<你的GitHub用户名>/dsh-root-bridge/releases) 下载
   `dsh-root-bridge-v1.5.zip`，KernelSU → 模块 → 安装 → 重启。
   重启后在 DSH 的终端里确认：`dsh-root --status`
2. **再装这个插件**：
   - DSH Go：设置 › 插件 › 插件市场，搜 `dsh-root-bridge`，装到当前主机；
   - 或者装到电脑上的 DSH：`npm i dsh-root-bridge`（DSH 插件管理器）

## 工具

### `root_exec`

| 参数 | 说明 |
|---|---|
| `command` | 交给 Android 侧 `/system/bin/sh -c` 执行的命令 |
| `timeoutMs` | 超时毫秒，默认 60000，最大 600000 |

返回 `{ output, exitCode }`。

例：

```text
root_exec({ command: "id -u; uname -m" })
→ exit 0
  0
  aarch64
```

## 已知限制

- `pm` / `am` / `settings` / `input` / `wm` 这类 Android 框架命令会报
  `Failed transaction (2147483646)`：ColorOS 的 binder 限制，root 域也绕不过。
- 需要配套 KernelSU 模块处于启用状态；桥没跑时工具会提示怎么恢复。
- 这个插件只负责「调用」，不会自己提权、也不会替你装模块。

## 安全

- root 桥只监听 `127.0.0.1`，token 在 App 私有目录，普通 App 读不到。
- **拿到 token 就等于拿到这台手机的 root**；不要把 token 或 `~/.dsh` 发出去。
- 装上模块 + 插件，等于让模型能在这台手机上执行 root 命令，请只在信任的设备上用。

## License

MIT
