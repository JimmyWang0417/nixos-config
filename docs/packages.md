# 软件包

## 作用

系统安装的软件在 `modules/packages.nix`。nixos-26.05 里有的属性用 `pkgs`。没有或过旧的属性放进 `orion.packages.unstable`，从 flake 输入 `nixpkgs-unstable` 取。这一路不单给某一个程序。

`deepseek-harness` 0.2.2-rc.3 没有 `dsh market` 子命令。GitHub 发布最新是 [0.2.2-rc.5](https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.2-rc.5)，nixpkgs-unstable 这份是 0.2.2-rc.3。官方 web 组合已经带文件树、终端、文档预览、网页搜索、轨迹和会话 token 统计，这些不写进插件列表。社区插件仍由 `dsh plugin --profile web add` 安装，不另装系统级 npm：`dshmarket`（dsh-market）、`dsh-context`（上下文构成，不压缩）、`dsh-cost-meter`（会话费用和订阅额度）、`dsh-auth-cookie-guard`（抬高请求头上限并清掉旧启动 cookie）、`dsh-connect-workbuddy`（本机 WorkBuddy；npm 上的 `dsh-workbuddy` 没有 bundle）、`@dmh2002/dsh-connect-qoder`（本机 Qoder）、`dsh-connect-trae`（本机 Trae）、`dsh-codex-connect`（ChatGPT 登录后的 Codex）、`dsh-btw`（侧问，不写主会话）、`@sputnikzaychik/dsh-qq-bot`（QQ 接到 DSH）。Nix 不钉插件版本。

## Typora

`modules/packages.nix` 从 `inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}` 取得 `nurPkgs`，系统包列表显式加入 `nurPkgs.typora`，避免与 nixpkgs 官方的同名 `pkgs.typora` 混淆。自有输入固定在 `5f78ae5b865c6cec9d855d6ea46719fe6e08098e`，并由 `flake.lock` 锁定。

该包迁自 AUR `typora-free-with-plugin` 的组合：Typora 免费测试版 `0.11.18` 与插件 `1.19.16`，derivation 版本为 `0.11.18-plugin-1.19.16`。对外包名和命令是 `typora`，桌面显示 Typora。Markdown 的默认程序仍为 Kate。它需要现有的 `allowUnfree` 设置。

上游包保留 `sources`、`typoraSrc`、`pluginSrc`、`extraFlags` 覆盖接口，例如在系统包列表中用下式替换 `nurPkgs.typora`：

```nix
(nurPkgs.typora.override {
  extraFlags = [ "--disable-gpu" ];
})
```

`typoraSrc` 与 `pluginSrc` 可以传入自行固定的源码；`sources` 可替换版本、下载地址与哈希元数据。插件的可写设置放在 `$HOME/.config/typora_plugin/settings.user.toml`，首次启动仅在缺失时创建，不把插件目录或 Nix store 改成可写。已有用户设置不覆盖；此版本插件固定使用 HOME 下的路径，不读取 `XDG_CONFIG_HOME`。详细安装、源码替换、配置迁移、插件更新与故障处理见 [nur-packages 的 Typora 文档](https://github.com/JimmyWang0417/nur-packages/blob/main/docs/typora.md)。

Typora 包、插件更新和包级构建检查由 nur-packages 的 GitHub Actions 维护；nixos-config 通过更新该输入修订接收更新，不另建一份 AUR 打包或插件更新脚本。

## 开关和默认值

`orion.packages.unstable` 的类型是包列表，默认 `[]`。Orion 目前有 `deepseek-harness`（命令 `dsh`）、`claude-code` 和 `codex`，都取自同一份 `nixpkgs-unstable`。`orion.packages.dshPlugins` 的类型是字符串列表，默认 `[]`。Orion 写下 `dshmarket`、`dsh-better-sidebar`、`dsh-context`、`dsh-cost-meter`、`dsh-auth-cookie-guard`、`dsh-skill-mcp-panel`、`dsh-genui`、`dsh-config-manager`、`dsh-ego-browser`、`dsh-free-search`、`dsh-ops`、`dsh-fast-mode`、`dsh-email`、`dsh-mobile`、`dsh-our-free-model`、`dsh-llm-retry-settings`、`@michengai/dsh-pua`、`dsh-soul`、`dsh-memory-palace`、`dsh-mem0`、`dsh-connect-workbuddy`、`@dmh2002/dsh-connect-qoder`、`dsh-connect-trae`、`dsh-codex-connect`、`dsh-btw`、`@sputnikzaychik/dsh-qq-bot`、`@ggboy123/dsh-paper-reader`、`dsh-paper-translator`、`dsh-paperdesk`、`dsh-paper-insight`、`dsh-cite`、`dsh-plugin-zotero`、`@fffangchenghao/dsh-latex-look`、`dsh-thesis`、`academic-research-skills-dsh`、`dsh-aha-tutor`、`dsh-study-coach`、`dsh-ai4scholar`、`dsh-slides`，不写版本。激活时若 `~/.dsh/profiles/web` 的依赖键和已保存 spec 里都没有这个名字，就执行 `dsh plugin --profile web add`。不在这份列表里的依赖会被移除。留下的 registry 依赖由 dsh-market 更新。

## 相关文件

- `flake.nix` 的输入 `nixpkgs-unstable`，锁在 `5d2b81a7a3be3e2f832879028e4d60abbf58e9a0`
- `flake.nix`、`flake.lock` 的自有 `nur-packages` 输入：提供 Typora、Qoder CN 0.5.16 和主题包。Trae 3.6.20 用 `nur.repos.lonerOrz.trae`。WorkBuddy 5.6.2.40046327 用 `nur.repos.MCSeekeri.workbuddy-linux`。没有安装 ZCode 或 DevEco。
- `modules/packages.nix`
- `hosts/orion/default.nix`

## 依赖

`deepseek-harness` 0.2.2-rc.3 没有 `dsh market` 子命令。GitHub 发布最新是 [0.2.2-rc.5](https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.2-rc.5)，nixpkgs-unstable 这份是 0.2.2-rc.3。官方 web 组合已经带文件树、终端、文档预览、网页搜索、轨迹和会话 token 统计，这些不写进插件列表。社区插件仍由 `dsh plugin --profile web add` 安装，不另装系统级 npm：`dshmarket`（dsh-market）、`dsh-context`（上下文构成，不压缩）、`dsh-cost-meter`（会话费用和订阅额度）、`dsh-auth-cookie-guard`（抬高请求头上限并清掉旧启动 cookie）、`dsh-connect-workbuddy`（本机 WorkBuddy；npm 上的 `dsh-workbuddy` 没有 bundle）、`@dmh2002/dsh-connect-qoder`（本机 Qoder）、`dsh-connect-trae`（本机 Trae）、`dsh-codex-connect`（ChatGPT 登录后的 Codex）、`dsh-btw`（侧问，不写主会话）、`@sputnikzaychik/dsh-qq-bot`（QQ 接到 DSH）。Nix 不钉插件版本。

## 未办或不迁

不装 `billion-context`（压缩整段上下文）。不装 `dsh-codex-effort-slider`、`dsh-whale-widget`、`dsh-pet`、`dsh-plugin-wallpaper-engine`、`dsh-meme`、`dsh-dream-skin`（观赏、桌宠、壁纸或皮肤）。不装 `dsh-usage-stats` 和 `dsh-balance-monitor`（和 `dsh-cost-meter` 抢同一费用位）。不装 `dsh-mnemon`、`dsh-remember`、`dsh-session-memory`、`dsh-context-memory`（和已装记忆插件抢同一段召回）。不装 `dsh-memory`、`dsh-scratchpad`、`dsh-latex-guard`、`dsh-plugin-academic-writing`。不装 `dsh-image-gen`、`dsh-one-click-polish`、`dsh-prompt-enhancer`、`dsh-reference-checker`、`dsh-course-assistant`、`dsh-computer-use`、`dsh-windows-mcp`、`@copylee/dsh-academic`（没有 engines 或 dsh peer，盖不住 0.2.2-rc.3）。不装 `dsh-zotero`（要 0.2.2-rc.4）和 `dsh-zotero-local`（和 `dsh-plugin-zotero` 抢同一个库）。不装 `dsh-qq` 和没有 bundle 的 `dsh-qqbot`。不装发布版只标明 0.2.0-rc.2 的 `@tencent-connect/dsh-qqbot`，以及会和 QQ bot 抢通道的 `@michengai/dsh-im-connect`。不装 `github:Faide-cyber/dsh-workbuddy`、没有 bundle 的 npm `dsh-workbuddy`、`dsh-zcode`。不装 Windows 专用的 `dsh-desktop-sidecar`、`dsh-computer-use-win`、`dsh-latex-studio`。NUR 上的 `nur.repos.ryan4yin.dsh` 是另一套 npm 封装，没有改用它。
