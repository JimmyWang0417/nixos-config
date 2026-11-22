# 桌面服务维护

## Flatpak

`modules/services/flatpak.nix` 显式设置 `services.flatpak.enable = false`。
系统不再提供 Flatpak 集成，也不再下载 Flathub 描述文件或执行开机注册任务。
该文件保留为独立策略入口，方便以后明确选择重新启用。

Plasma 默认也会因为启用 fwupd 而安装 Discover 软件商店；当前 Discover 包自带
Flatpak 后端。因此通过 `environment.plasma6.excludePackages` 排除 Discover，
同时保留 fwupd 服务和 `fwupdmgr` 固件更新命令。Flatpak 系统设置页面不再安装，
桌面文件选择、屏幕共享等 portal 功能继续保留。

本次仅修改目标 NixOS 配置，不清理已有的 Flatpak 应用、远程配置或用户数据；
AppImage、NUR 和其他 Nix 软件继续按各自模块配置。

## 定时任务

`modules/services/scheduling.nix` 显式关闭 cron。仓库没有声明系统 crontab，
Nix 清理、store 去重和日志轮转使用 systemd timer。`services.logrotate.enable`
继续开启；关闭 cron 不会停止日志轮转。以后若引入仅支持 crontab 的任务，需重新
审视这个选择。

## JACK 音频兼容

`modules/desktop/audio.nix` 保留 PipeWire、ALSA（含 32 位）、PulseAudio 兼容、
WirePlumber 与 rtkit，关闭已弃用的 `services.pipewire.jack.enable`。该旧选项会
向整个登录环境注入 `LD_LIBRARY_PATH`，当前 nixpkgs 明确建议改用按程序包装。

系统安装 `pkgs.pipewire.jack`，需要 JACK 的程序使用：

```sh
pw-jack 程序名 参数
```

这样只为该程序及其子进程选择 PipeWire 的 JACK 兼容库。普通桌面音频仍通过
PipeWire 的 ALSA/PulseAudio 接口运行；不额外启动 JACK daemon。

## Neovim

移除 Syntastic 与重复的通用 clangd 注册，保留 Coc 与 `coc-clangd` 扩展；
clangd 使用 Nix 提供的命令。见 [Neovim 配置](neovim.md)。
