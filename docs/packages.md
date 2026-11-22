# 软件包

## 作用

`modules/packages.nix` 是兼容入口，实际组合由 `modules/packages/default.nix` 加载。全局 `pkgs` 已统一来自 `nixpkgs-unstable` 输入锁定的 `nixos-unstable`，包括系统服务、桌面、驱动、字体、Home Manager 和开发工具。`orion.packages.unstable` 保留原有扩展接口，列表里的应用也使用同一个 `pkgs`；不再为个别应用重新 import 一套包。stable 只保留 `nixpkgs` 输入和 `pkgsStable` 接口，现有模块不调用它。自定义 NUR 包保留其功能和配方，并将构建依赖跟随 unstable。完整版本核对和剩余上游差距见 [迁移评估](unstable-migration.md)，目录边界与增加应用的方法见 [配置结构](architecture.md)。

## 模块边界

软件清单是纯数据，放在 `modules/packages/catalog/`：`core.nix` 管基础命令，`development.nix` 管编辑器、编译器和语言工具，`desktop-apps.nix` 管桌面与 NUR 应用，`storage.nix` 管文件系统和数据库工具，`hardware.nix` 管硬件诊断，`media.nix` 管播放器与编解码，`desktop-tools.nix` 管桌面辅助工具。`catalog.nix` 按明确的组顺序组合这些列表，再追加公共接口 `orion.packages.unstable`。增加软件时修改所属清单，不把服务、用户配置或激活脚本混进列表。

应用行为独立于清单：`browsers.nix` 配置 Firefox 更新策略和 Chromium/Edge 的 Plasma native messaging；`gaming.nix` 启用原有 Steam 集成；`with-ozone.nix` 统一封装现有的 Wayland 参数。`options.nix` 保留原有 `orion.packages.unstable` 类型和默认值；`policy.nix` 集中现有 unfree、钉钉及 GTK2 兼容例外。它们沿用同一套全局 unstable 包，重组不改变软件来源或版本。

DSH 结构、扩展与激活行为见 [DSH 文档](dsh.md)。DSH 独立在 `modules/programs/dsh/`，`modules/dsh.nix` 保留兼容入口。`plugins/default.nix` 按明确顺序组合 core、context、workbench、interaction、models、behavior、connectors、chat、reading、bibliography、writing、learning、slides 共十三组；38 个插件名称及安装次序保持不变。`options.nix` 保留公共接口 `orion.packages.dshPlugins`，`runtime.nix` 负责断言和 Home Manager 激活，`reconcile-plugins.py` 单独负责现有依赖与清单的协调，不在 Nix 表达式内嵌 Python。

2026-11-22 检查时，本机 `DSH_HOME` 未设置，`~/.dsh`、`~/.config/dsh` 和 `~/.local/share/dsh` 均不存在，因此没有可迁入的普通运行时配置。这里声明已有的插件选择和安装行为；账号、provider 配置与令牌不写入仓库，也不在激活时覆盖用户随后创建的设置。

`deepseek-harness` 0.2.2-rc.3 没有 `dsh market` 子命令。GitHub 发布最新是 [0.2.2-rc.5](https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.2-rc.5)，nixpkgs-unstable 这份是 0.2.2-rc.3。官方 web 组合已经带文件树、终端、文档预览、网页搜索、轨迹和会话 token 统计，这些不写进插件列表。社区插件仍由 `dsh plugin --profile web add` 安装，不另装系统级 npm：`dshmarket`（dsh-market）、`dsh-context`（上下文构成，不压缩）、`dsh-cost-meter`（会话费用和订阅额度）、`dsh-auth-cookie-guard`（抬高请求头上限并清掉旧启动 cookie）、`dsh-connect-workbuddy`（本机 WorkBuddy；npm 上的 `dsh-workbuddy` 没有 bundle）、`@dmh2002/dsh-connect-qoder`（本机 Qoder）、`dsh-connect-trae`（本机 Trae）、`dsh-codex-connect`（ChatGPT 登录后的 Codex）、`dsh-btw`（侧问，不写主会话）、`@sputnikzaychik/dsh-qq-bot`（QQ 接到 DSH）、`dsh-our-free-model`（免登录的 Zen/Kilo 模型；包内 ZCode 渠道不单独当连接器）、`@michengai/dsh-pua`（验收循环，语气可关）、`dsh-soul`（人设，不是记忆）、`dsh-paper-insight`（论文到产品、沙箱和 PRD）、`dsh-thesis`（学位论文九阶段）。侧栏、论文、引文、Zotero、LaTeX 和学习插件的 id 与「开关和默认值」相同。Nix 不钉插件版本。

## Typora

`modules/packages/catalog/desktop-apps.nix` 从 `inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}` 取得 `nurPkgs`，系统包列表显式加入 `nurPkgs.typora`，避免与 nixpkgs 官方的同名 `pkgs.typora` 混淆。自有输入修订由 `flake.lock` 锁定。

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

`orion.packages.unstable` 的类型是包列表，默认包含 `deepseek-harness`（命令 `dsh`）、`claude-code`、`codex`、`android-studio` 和 `openlogi`。所有条目直接来自全局 unstable `pkgs`，沿用系统的 `allowUnfree`，与用户服务引用一致。版本由 `flake.lock` 决定。`orion.packages.dshPlugins` 的类型是字符串列表，默认 `[]`。Orion 写下 `dshmarket`、`dsh-better-sidebar`、`dsh-context`、`dsh-cost-meter`、`dsh-auth-cookie-guard`、`dsh-skill-mcp-panel`、`dsh-genui`、`dsh-config-manager`、`dsh-ego-browser`、`dsh-free-search`、`dsh-ops`、`dsh-fast-mode`、`dsh-email`、`dsh-mobile`、`dsh-our-free-model`、`dsh-llm-retry-settings`、`@michengai/dsh-pua`、`dsh-soul`、`dsh-memory-palace`、`dsh-connect-workbuddy`、`@dmh2002/dsh-connect-qoder`、`dsh-connect-trae`、`dsh-codex-connect`、`dsh-btw`、`@sputnikzaychik/dsh-qq-bot`、`@ggboy123/dsh-paper-reader`、`dsh-paper-translator`、`dsh-paperdesk`、`dsh-paper-insight`、`dsh-cite`、`dsh-plugin-zotero`、`@fffangchenghao/dsh-latex-look`、`dsh-thesis`、`academic-research-skills-dsh`、`dsh-aha-tutor`、`dsh-study-coach`、`dsh-ai4scholar`、`dsh-slides`，不写版本。激活时若 `~/.dsh/profiles/web` 的依赖键和已保存 spec 里都没有这个名字，就执行 `dsh plugin --profile web add`。不在这份列表里的依赖会被移除。留下的 registry 依赖由 dsh-market 更新。

## 相关文件

- `flake.nix` 的输入 `nixpkgs-unstable` 跟踪 `nixos-unstable`，修订由 `flake.lock` 锁定
- `flake.nix`、`flake.lock` 的自有 `nur-packages` 输入：提供 Typora、Qoder CN 0.5.16（`qoder-cn`）、Trae CN 构建 2.3.105403（应用版本 3.4.22，`trae-cn`）、CC Switch 4.0.36（`cc-switch`）和主题包。国际版 Qoder 0.5.16 是同仓库的 `qoder`，不安装。国际版 Trae 仍是 `nur.repos.lonerOrz.trae`，不安装。WorkBuddy 5.6.2.40046327 用 `nur.repos.MCSeekeri.workbuddy`。没有安装 ZCode。DevEco Studio 由 `modules/programs/deveco.nix` 安装，下载和组装在 nur-packages。CC Switch 不再取锁定的 nixpkgs-unstable 3.16.5。
- `modules/packages.nix`：兼容入口
- `modules/packages/default.nix`、`catalog.nix`、`catalog/`：模块与软件组组合
- `modules/packages/options.nix`、`policy.nix`、`browsers.nix`、`gaming.nix`、`with-ozone.nix`：公共接口、兼容策略和应用行为
- `modules/programs/dsh/`、`modules/dsh.nix`：DSH 插件分组、兼容接口与运行时安装
- `hosts/orion/default.nix`

## 未办或不迁

不装 `billion-context`（压缩整段上下文）。不装 `dsh-codex-effort-slider`、`dsh-whale-widget`、`dsh-pet`、`dsh-plugin-wallpaper-engine`、`dsh-meme`、`dsh-dream-skin`（观赏、桌宠、壁纸或皮肤）。不装 `dsh-usage-stats` 和 `dsh-balance-monitor`（和 `dsh-cost-meter` 抢同一费用位）。不装 `dsh-mnemon`、`dsh-remember`、`dsh-session-memory`、`dsh-context-memory`（和已装记忆插件抢同一段召回）。不装 `dsh-memory`、`dsh-scratchpad`、`dsh-latex-guard`、`dsh-plugin-academic-writing`。不装 `dsh-image-gen`、`dsh-one-click-polish`、`dsh-prompt-enhancer`、`dsh-reference-checker`、`dsh-course-assistant`、`dsh-computer-use`、`dsh-windows-mcp`、`@copylee/dsh-academic`（没有 engines 或 dsh peer，盖不住 0.2.2-rc.3）。不装 `dsh-zotero`（要 0.2.2-rc.4）和 `dsh-zotero-local`（和 `dsh-plugin-zotero` 抢同一个库）。不装 `dsh-qq` 和没有 bundle 的 `dsh-qqbot`。不装发布版只标明 0.2.0-rc.2 的 `@tencent-connect/dsh-qqbot`，以及会和 QQ bot 抢通道的 `@michengai/dsh-im-connect`。不装 `github:Faide-cyber/dsh-workbuddy`、没有 bundle 的 npm `dsh-workbuddy`、`dsh-zcode`。不装 `dsh-mem0`（`dsh-memory-palace` 更好：本地 Markdown 能直接改，不用 Mem0 账号或 Qdrant，两份每轮召回会抢同一段上下文）。不装 `@aixineiar/dsh-side-chat`（和 `dsh-btw` 做同一件侧问，只是三种模式会裁掉工具，不另装）。不装 `@ahggg/dsh-side-chat`（`dsh-llm` peer 钉在 0.2.1-rc.2，盖不住 0.2.2-rc.3）。不装 Windows 专用的 `dsh-desktop-sidecar`、`dsh-computer-use-win`、`dsh-latex-studio`。NUR 上的 `nur.repos.ryan4yin.dsh` 是另一套 npm 封装，没有改用它。
