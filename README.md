这是 Orion-Laptop（HP OMEN 16）的 NixOS 复刻配置：用模块化 flake 描述当前 Manjaro 主机的硬件、双显卡、Plasma 桌面布局、中文输入和软件清单。仓库只做求值，不执行 `nixos-rebuild`，也不改正在使用的引导和磁盘。

2026-11-16 检查过：`refs/heads/nixos-26.11` 不存在，`https://channels.nixos.org/nixos-26.11` 返回 404，home-manager 也没有 `release-26.11`。测试线还没发布，所以这个 flake 跟踪当前稳定版 `nixos-26.05` 和 `home-manager` 的 `release-26.05`，不用 `nixos-unstable`。

默认登录会话是 Plasma X11，会话名 `plasmax11`。Wayland 会话 `plasma` 仍会装上，但不是默认项。输入法只保留 fcitx5 一条路径（GTK、Qt、X11、Wayland、Electron）。现场的 `/etc/environment` 里 `XMODIFIERS` 写了两遍，并且 `GLFW_IM_MODULE=ibus` 和 fcitx 冲突；GLFW 那一项已去掉。字体不再叠多份 fontconfig，只留一条 CJK 回退链。细节在 `inventory/optimizations.md`，对照表在 `inventory/适配清单.md`。

## 再加一台机器

共享模块在 `modules/`，用 `orion.*` 开关，默认关闭，由主机文件打开。新增机器不要改这些模块。

1. 复制 `hosts/example.nix` 为 `hosts/<名字>/default.nix`。
2. 在 `flake.nix` 的 `nixosConfigurations` 里加一条属性，带上 `system`、`hostName` 和 `modules = [ ./hosts/<名字> ]`。
3. 只改这三处：主机名、硬件（文件系统、initrd、显卡 PCI）、要打开的 `orion.*` 配置。

用户 jimmywang0417 的 Plasma 布局在 `home/jimmy.nix`，由主机文件导入。另一台机器可以同样导入，也可以不导入。
