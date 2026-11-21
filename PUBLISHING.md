# 发布步骤（最短路径）

一共三个地方：GitHub、npm、DSH Go 插件市场。按顺序做，每一步只动一次。

先把 `4344734` 和 `LICENSE` 里的 `<YOUR NAME>` 换成你自己的（下面有命令）。

```sh
cd /root/workspace/dsh-root-bridge
grep -rl '4344734' . | xargs sed -i 's/4344734/你的名字/g'
sed -i 's/<YOUR NAME>/你的名字/g' LICENSE
```

## 1️⃣ GitHub（放模块和源码）

1. 打开 https://github.com/new ，仓库名 `dsh-root-bridge`，选 Public，**不要**勾 README。
2. 在 DSH 终端里：

```sh
cd /root/workspace/dsh-root-bridge
git remote add origin https://github.com/你的名字/dsh-root-bridge.git
git branch -M main
git push -u origin main
```

> 会要账号密码：GitHub 不认密码，要 Personal Access Token。
> 生成：GitHub → Settings → Developer settings → Personal access tokens →
> Tokens (classic) → Generate new token → 勾 `repo` → 复制当密码用。

3. 发模块 Release（网页操作）：
   Releases → Draft a new release → Tag `v1.5` → 标题 `Module v1.5` →
   上传 `dist/dsh-root-bridge-v1.5.zip` → Publish。

## 2️⃣ npm（放插件）

```sh
cd /root/workspace/dsh-root-bridge/plugin
npm login --registry=https://registry.npmjs.org
npm publish --registry=https://registry.npmjs.org --access public
```

> `npm login` 会给你一个链接和验证码，在手机浏览器里打开登录即可。
> 发布成功后可查：`npm view dsh-root-bridge version --registry=https://registry.npmjs.org`

以后改版本：改 `plugin/package.json` 的 `version`，再 `npm publish`。

## 3️⃣ DSH Go 插件市场（放目录条目）

市场仓库：https://github.com/ccch1mneyyy/dsh-go-market

1. Fork 这个仓库。
2. 把 `market/dsh-root-bridge.json` 上传到 fork 的 `plugins/dsh-root-bridge.json`
   （GitHub 网页：Add file → Upload files）。
3. 提 Pull Request 到 `main`。
4. 自动检查通过会自动合并，几分钟后 App 的插件市场「全部」里就能搜到。

要求已满足：精确版本在 npm 上、MIT 许可、`package.json` 里有 `dsh.bundle.patch`、
包小于 50 MB。风险标记（网络/文件读取）会自动标给用户看，不影响上架。

## 以后发新版

1. 模块：改 `module/module.prop` 的 version/versionCode → `sh build.sh` →
   GitHub 发新 Release。
2. 插件：改 `plugin/package.json` 的 version → `npm publish` →
   改 `market/dsh-root-bridge.json` 的 version → 在市场仓库提 PR。
