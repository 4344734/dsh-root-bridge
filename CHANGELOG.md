# Changelog

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
