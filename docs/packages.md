# 软件包

## 作用

系统安装的软件在 `modules/packages.nix`。nixos-26.05 里有的属性用 `pkgs`。没有或过旧的属性放进 `orion.packages.unstable`，从 flake 输入 `nixpkgs-unstable` 取。这一路不单给某一个程序。

`deepseek-harness` 0.2.2-rc.1 没有 `dsh market` 子命令。市场是独立 npm 包 `dshmarket`（dsh-market），nixpkgs-unstable 里没有这个属性。web profile 还写下 `dsh-better-sidebar`（文件树、编辑器、终端）、`dsh-context`（上下文构成，不压缩）、`dsh-cost-meter`（会话费用和订阅额度）、`dsh-auth-cookie-guard`（抬高请求头上限并清掉旧启动 cookie）、`github:Faide-cyber/dsh-workbuddy`（包名 `dsh-workbuddy`，接入 WorkBuddy 模型；npm 上的 `dsh-workbuddy` 没有 bundle）。选型对照了 awesome-dsh-plugin 和四篇小黑盒帖子（link_id `74e872c888ed`、`c1b172b3be3f`、`d8d0727d6d45`、`055972cc9458`）。dshmarket 负责安装和更新，Nix 不钉版本。

## Typora

`modules/packages.nix` 从 `inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}` 取得 `nurPkgs`，系统包列表显式加入 `nurPkgs.typora`，避免与 nixpkgs 官方的同名 `pkgs.typora` 混淆。自有输入固定在 `9a4bcf65fac8de0738e002e8bfe00a68ac4019b6`，并由 `flake.lock` 锁定。

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

`orion.packages.unstable` 的类型是包列表，默认 `[]`。Orion 目前有一项：`deepseek-harness` 0.2.2-rc.1（命令 `dsh`）。`orion.packages.dshPlugins` 的类型是字符串列表，默认 `[]`。Orion 写下 `dshmarket`、`dsh-better-sidebar`、`dsh-context`、`dsh-cost-meter`、`dsh-auth-cookie-guard`、`github:Faide-cyber/dsh-workbuddy`，不写版本。激活时若 `~/.dsh/profiles/web` 的依赖键和已保存 spec 里都没有这个名字，就执行 `dsh plugin --profile web add`。已经装上的 registry 依赖留给 dsh-market 更新。

## 相关文件

- `flake.nix` 的输入 `nixpkgs-unstable`，锁在 `5d2b81a7a3be3e2f832879028e4d60abbf58e9a0`
- `flake.nix`、`flake.lock` 的自有 `nur-packages` 输入：提供 Typora 和主题包
- `modules/packages.nix`
- `hosts/orion/default.nix`

## 依赖

`deepseek-harness` 的默认沙箱要在 `PATH` 上找到 `bwrap`，所以同一份系统包列表里有 `pkgs.bubblewrap`。模型凭据不入库。`dsh plugin` 把插件装进 `~/.dsh`，不进 Nix store。

## 未办或不迁

不装 `billion-context`（帖子里写成雷霆大思考的原因，会把上下文压得很低）。不装 `dsh-codex-effort-slider`、`dsh-whale-widget`、`dsh-pet`、`dsh-plugin-wallpaper-engine`（观赏或桌宠）。不装 `dsh-usage-stats` 和 `dsh-balance-monitor`（和费用插件重复，发布的 peer 也接不上 0.2.2-rc.1）。不装 `dsh-mnemon`（每轮注入，费 token）。不装 `dsh-at-file` 0.6.3（2026-08 停更，没有 `engines.dsh`）。不装 `dsh-connect-workbuddy`、即时通讯、浏览器接管、视觉和画图类（窄）。NUR 上的 `nur.repos.ryan4yin.dsh` 是 0.2.2-rc.3，另一套 npm 封装，没有改用它。
