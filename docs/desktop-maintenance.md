# 桌面服务维护

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
