# 发布步骤（仓库所有者用）

## 首次发布到 GitHub

```sh
cd dsh-root-bridge

# 1. 改成你自己的身份（只对这个仓库生效）
git config user.name  "你的名字"
git config user.email "you@example.com"

# 2. 如果还没初始化（本目录已带初始提交，可跳过）
# git init && git add -A && git commit -m "init"

# 3. 在 GitHub 网页上新建空仓库（不要勾 README），然后：
git remote add origin https://github.com/<你的用户名>/dsh-root-bridge.git
git branch -M main
git push -u origin main
```

## 发 Release

1. 改 `module/module.prop` 的 `version` / `versionCode`
2. 改 `CHANGELOG.md`，运行 `sh build.sh`
3. GitHub → Releases → Draft a new release
4. Tag：`v1.4`；标题：`DSH Go Root Bridge v1.4`
5. 上传 `dist/dsh-root-bridge-v1.4.zip`
6. 发布

## 提交到 KernelSU 模块仓库（可选）

KernelSU 管理器的「模块仓库」只收录索引里的仓库。按它的收录要求提 PR：

- 仓库有 `README`、可用的 release、模块 zip 能在 KernelSU 里安装
- 模块 zip 里的 `module.prop` 有 `id` / `version` / `versionCode`
- 到 KernelSU 模块仓库的索引仓库提 PR，加上你的仓库地址

## 注意

- 发布前把 `LICENSE` 里的 `<YOUR NAME>` 换成你自己
- 不要把 `~/.dsh`、token、设备路径等私人信息带进仓库（本仓库源码里只有 App 包名，没有 token）
