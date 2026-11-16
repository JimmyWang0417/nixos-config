这是 Orion-Laptop（HP OMEN 16）的 NixOS 复刻配置：用模块化 flake 描述当前 Manjaro 主机的硬件、双显卡、Plasma 桌面布局、中文输入和软件清单。仓库只做求值，不执行 `nixos-rebuild`，也不改正在使用的引导和磁盘。

2026-11-16 检查过：`refs/heads/nixos-26.11` 不存在，`https://channels.nixos.org/nixos-26.11` 返回 404，home-manager 也没有 `release-26.11`。测试线还没发布，所以这个 flake 跟踪当前稳定版 `nixos-26.05` 和 `home-manager` 的 `release-26.05`，不用 `nixos-unstable`。

默认登录会话是 Plasma X11，会话名 `plasmax11`。Wayland 会话 `plasma` 仍会装上，但不是默认项。输入法只保留 fcitx5 一条路径（GTK、Qt、X11、Wayland、Electron）。现场的 `/etc/environment` 里 `XMODIFIERS` 写了两遍，并且 `GLFW_IM_MODULE=ibus` 和 fcitx 冲突；GLFW 那一项已去掉。字体不再叠多份 fontconfig，只留一条 CJK 回退链。细节在 `inventory/optimizations.md`，对照表在 `inventory/适配清单.md`。

## 快捷键

默认是迁过来的 KDE 快捷键，`orion.shortcuts.profile = "current"`，不启用 keyd。仿 macOS 的一套已经可以切换：只在主机文件里写成 `"macos"`。按住 Super 时当作 Command。改回 `"current"` 会关掉 keyd。这不是未办项。

## 未办配置

这些还没有做完。不是已迁移功能的简介。

### 留在本机，不能入库

只记种类，没有秘密内容。

- fcitx5 拼音用户词库：`user.dict` 与 `user.history`
- Win10 字体包 `ttf-ms-win10-auto` 里的字体文件
- JetBrains 许可证文件
- Clash Verge 的订阅和 `.encryption_key`
- anytls 私钥（`~/.ssh` 里 `id_ed25519_anytls_` 开头的文件）
- 坚果云 rclone 凭据
- CC Switch 数据目录
- NetworkManager 系统连接（`system-connections`）
- botmux 的 `bots.json`
- v2rayN 的 `guiConfigs`
- WPS 的 `license2.dat`

### nixpkgs 26.05 没有、也还没接入的包

- alder
- crm
- udf-http-range-proxy
- keepassxc-unlock
- verilog-format-git
- xjtu-course-genius
- xjtutoolbox-bin
- botmux-bin
- animeko 6.4.0（nixpkgs 里的 `animeko` 5.3.2 标记为 broken，没有写入）

### 等用户决定再写进配置

百度网盘桌面版、钉钉桌面版、深信服 EasyConnect、华为云会议、Grok Bot 桌面版、WPS 教育版、Typora 的 AUR 包、`/opt/anaconda`。

这些没有因为「也许以后要装」而写进模块。主机 `hosts/orion/default.nix` 里 `orion.nix.allowUnfree = true` 已经打开，那是给已经映射的 NVIDIA 用户态驱动，以及 Chrome、Edge、VS Code、JetBrains、Discord、Steam、Obsidian 用的，不是为了把上面这组客户端加进来。

### 开机项指向已卸载程序，默认不迁移

ToDesk、1Password、RustDesk、Waydroid、`apm-daily-update`。v2rayN 和正在使用的 Clash 重叠，默认不迁移。

### 配置里已留接口但还没填实的

- sops：`modules/secrets.nix` 只登记了本机 age 密钥路径和主机 SSH 密钥路径。`secrets/README.md` 和 `.sops.yaml` 里还没有具体 secret 名字，`keys` 是空的，也没有密文。
- 快捷键不是未办。`modules/shortcuts.nix` 已提交。默认 `orion.shortcuts.profile = "current"`，此时 `services.keyd.enable` 为 false。改成 `"macos"` 才启用 keyd。toplevel 已求值通过。

### NUR

还在查上面「nixpkgs 26.05 没有」那一组名字在 NUR 里有没有对应包：alder、crm、udf-http-range-proxy、keepassxc-unlock、verilog-format-git、xjtu-course-genius、xjtutoolbox-bin、botmux-bin、animeko。核对还没结束，这里不写任何 NUR 属性名。

## 再加一台机器

共享模块在 `modules/`，用 `orion.*` 开关，默认关闭，由主机文件打开。新增机器不要改这些模块。

1. 复制 `hosts/example.nix` 为 `hosts/<名字>/default.nix`。
2. 在 `flake.nix` 的 `nixosConfigurations` 里加一条属性，带上 `system`、`hostName` 和 `modules = [ ./hosts/<名字> ]`。
3. 只改这三处：主机名、硬件（文件系统、initrd、显卡 PCI）、要打开的 `orion.*` 配置。

用户 jimmywang0417 的 Plasma 布局在 `home/jimmy.nix`，由主机文件导入。另一台机器可以同样导入，也可以不导入。
