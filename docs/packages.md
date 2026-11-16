# 软件包

## 作用

系统安装的软件在 `modules/packages.nix`。nixos-26.05 里有的属性用 `pkgs`。没有或过旧的属性放进 `orion.packages.unstable`，从 flake 输入 `nixpkgs-unstable` 取。这一路不单给某一个程序。

`deepseek-harness` 0.2.2-rc.1 另外带三个社区插件，挂到 web profile：`dsh-better-sidebar` 0.32.0（文件树、编辑器、终端）、`dsh-context` 0.85.1（上下文构成，不压缩）、`dsh-cost-meter` 1.9.70（会话费用和订阅额度）。选型对照了 awesome-dsh-plugin 和四篇小黑盒帖子（link_id `74e872c888ed`、`c1b172b3be3f`、`d8d0727d6d45`、`055972cc9458`）。

## 开关和默认值

`orion.packages.unstable` 的类型是包列表，默认 `[]`。Orion 目前有一项：`deepseek-harness` 0.2.2-rc.1（命令 `dsh`）。三个插件没有单独的开关，激活时链进 `~/.dsh/profiles/web`，并保留已有的 bundle 名单。新 profile 的官方层仍是 `@deepseek-ai/dsh-base` 和 `@deepseek-ai/dsh-web-app`。`dsh-better-sidebar` 用 0.32.0，因为 0.32.1 要求 `0.2.2-rc.2`。

## 相关文件

- `flake.nix` 的输入 `nixpkgs-unstable`，锁在 `5d2b81a7a3be3e2f832879028e4d60abbf58e9a0`
- `modules/packages.nix`
- `hosts/orion/default.nix`

## 依赖

`deepseek-harness` 的默认沙箱要在 `PATH` 上找到 `bwrap`，所以同一份系统包列表里有 `pkgs.bubblewrap`。模型凭据不入库。插件里 `@deepseek-ai/*` 由正在运行的 `dsh` 提供。包内另外带上发布物自己引用的 `ws` 8.23.0、`yaml` 2.9.1、`zod` 4.6.7。

## 未办或不迁

不装 `billion-context`（帖子里写成雷霆大思考的原因，会把上下文压得很低）。不装 `dsh-codex-effort-slider`、`dsh-whale-widget`、`dsh-pet`、`dsh-plugin-wallpaper-engine`（观赏或桌宠）。不装 `dsh-usage-stats` 和 `dsh-balance-monitor`（和费用插件重复，发布的 peer 也接不上 0.2.2-rc.1）。不装 `dsh-mnemon`（每轮注入，费 token）。不装 `dsh-at-file` 0.6.3（2026-08 停更，没有 `engines.dsh`）。不装 `dshmarket`（会再装别的插件）。不装 `dsh-connect-workbuddy`、即时通讯、浏览器接管、视觉和画图类（窄）。NUR 上的 `nur.repos.ryan4yin.dsh` 是 0.2.2-rc.3，另一套 npm 封装，没有改用它。
