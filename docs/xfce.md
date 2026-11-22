# Xfce X11 备用桌面

默认登录会话是 Plasma Wayland（`plasma`）。需要 ToDesk 控制这台机器时，在 SDDM
登录界面选择 Xfce（`xfce`）并登录；远程端看到的是这个实际 X11 会话。
仅安装 Xfce 并不会让已登录的 Plasma Wayland 会话变成 X11。

Xfce 由同一锁定的 unstable 包集提供，Home Manager 配置位于 `home/xfce.nix`。
外观依据 `inventory/plasma-layout.md` 和已有 `home/plasma/` 设置适配：

- WhiteSur 浅色 GTK 和 xfwm4 窗口主题，使用接近现有 Breath 的绿色强调色。
- Tela 图标，WhiteSur 光标，与 Plasma 同源的 WhiteSur 壁纸。
- 顶部状态面板和底部居中启动面板，厚度 44；保留常用应用、工作区、托盘与时钟。
- 两个工作区，Noto Sans CJK SC 字体；按笔记本既有 150% 使用习惯设置字体 DPI，
  不强制改动显示器的分辨率、布局或变换。

这套设置写入 Xfce 自己的 xfconf 与面板配置，不设置 Home Manager 的全局 GTK
主题，也不改 Plasma 的布局文件。Xfce 的输入法由 X11 会话脚本和限定桌面的
fcitx5 自启动提供；Plasma Wayland 继续由 KWin 启动 fcitx5。

安装或重建后在 Xfce 登录中检查面板、托盘、输入法和 ToDesk。本次只修改并验证
NixOS 配置，未对正在运行的 Manjaro 桌面应用这些设置。

可单独验证主题资源（不会构建整套系统）：

```sh
nix build --impure --no-link --file tests/xfce-assets.nix
```

该检查会核对 GTK、xfwm4、光标、Tela 图标和实际壁纸文件存在；它不代替真实
Xfce 登录后的屏幕、输入法和远程控制检查。
