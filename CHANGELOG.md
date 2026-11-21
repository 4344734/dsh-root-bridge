# Changelog

## v1.6

- 发布版不再附带 ColorOS 解冻助手（该助手此前每 30 秒检查一次 cgroup，属于可选的省电争议功能）
- 模块只保留 root 桥和容器客户端看护

## 插件 0.1.0（npm: dsh-root-bridge）

- 新增 `root_exec` 工具：通过 KernelSU 模块的 root 桥，在 Android 侧以真 root 执行命令
- 输出合并 stdout/stderr 和退出码；支持超时
- 桥没跑或没装模块时给出可操作的提示

## v1.5

- 去掉周期轮询：桥改成父进程 `wait` 监督，退出即重拉（健康时零唤醒）
- 客户端补回改成 `inotifyd` 文件事件驱动，开机只检查一次
- 解冻助手：默认 5 秒 → 30 秒，轮询改用 shell 内建 `read` 不再 fork；
  可用 `THAW_ENABLE=0` / `THAW_INTERVAL` 调整
- 实测空闲唤醒：旧版 156 次/分 → 新版 2 次/分

## v1.4

- 解冻名单可配置：`/data/adb/dsh-root-bridge.conf` 的 `THAW_APPS`（默认只解冻 DSH Go）
- 开机早于解锁、`/data/data` 还读不到时，uid 解析会稍后自动重试
- 模块描述更新

## v1.3

- `dsh-root` 新增：`--stream` 流式输出、`--timeout` 超时、`--as` 换 uid、
  `--put` / `--get` 文件传输、`--bg` / `--jobs` / `--job` / `--kill` 后台任务
- 框架命令（`pm` / `am` / `settings` / `input`）失败时附提示

## v1.2

- 看门狗：桥挂了 15 秒内自动重拉（原来是 60 秒只补客户端）
- 客户端按 md5 校验，被更新换成旧版也会替换
- rootfs / token 路径自动识别，包名或运行环境路径变化后不用改脚本
- 新增 `uninstall.sh`，卸载时清理临时文件和容器客户端

## v1.1

- 看门狗把容器里的 `dsh-root` 客户端自动补回，App 更新后不用手动恢复

## v1.0

- 初版：`127.0.0.1:47913` 的 root 命令桥 + `dsh-root` 客户端
- KernelSU 模块开机自启
