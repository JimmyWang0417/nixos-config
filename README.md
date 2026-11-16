这是 Orion-Laptop（HP OMEN 16）的 NixOS 复刻配置：用模块化 flake 描述当前 Manjaro 主机的硬件、双显卡、Plasma 桌面布局、中文输入和软件清单。仓库只做求值，不执行 `nixos-rebuild`，也不改正在使用的引导和磁盘。

2026-11-16 检查过：`refs/heads/nixos-26.11` 不存在，`https://channels.nixos.org/nixos-26.11` 返回 404，home-manager 也没有 `release-26.11`。测试线还没发布，所以这个 flake 跟踪当前稳定版 `nixos-26.05` 和 `home-manager` 的 `release-26.05`，不用 `nixos-unstable`。

运行中的会话是 Plasma Wayland（`XDG_SESSION_TYPE=wayland`，会话名 `plasma`），所以默认会话写成 `plasma`，SDDM 也在 Wayland 上启动。`/etc/sddm.conf.d/kde_settings.conf` 里的自动登录仍写着 `Session=plasmax11`，那是配置文件和当前会话不一致的地方；自动登录用户仍是 `jimmywang0417`。输入法只保留 fcitx5 一条路径（GTK、Qt、X11、Wayland、Electron）。现场的 `/etc/environment` 里 `XMODIFIERS` 写了两遍，并且 `GLFW_IM_MODULE=ibus` 和 fcitx 冲突；GLFW 那一项已去掉。字体不再叠多份 fontconfig，只留一条 CJK 回退链。细节在 `inventory/optimizations.md`，对照表在 `inventory/适配清单.md`。

Linux 根文件系统在 btrfs `UUID=fd32207f-8a11-48d7-9d04-9316cdb8c265` 的 `@`、`@home`、`@cache`、`@log` 上，ESP `UUID=0AF1-1155` 与 Windows 共用。没有活动的 swapfile，所以没有写入 `resume` / `resume_offset`。显卡是 Intel 核显显示加 NVIDIA PRIME offload，不是 sync。

## 快捷键

默认是迁过来的 KDE 快捷键，`orion.shortcuts.profile = "current"`，不启用 keyd。仿 macOS 的一套已经可以切换：只在主机文件里写成 `"macos"`。按住 Super 时当作 Command。改回 `"current"` 会关掉 keyd。这不是未办项。

## 未办配置

这些还没有做完。不是已迁移功能的简介。

### 已用 sops 加密入库

只写 secret 名。明文不在仓库里。运行时路径是 `/run/secrets/<名字>`，说明在 `secrets/README.md`。

fcitx5-pinyin、clash-verge、anytls-ssh-key、rclone-webdav、jetbrains-licenses、wps-license、botmux-bots。

### 留在本机，不能入库

只记种类，没有秘密内容。

- Win10 字体包 `ttf-ms-win10-auto` 里的字体文件
- CC Switch 数据目录
- v2rayN 的 `guiConfigs`
- NetworkManager 系统连接（`/etc/NetworkManager/system-connections`）未读到，没有加密

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

- sops 的年龄私钥仍只在本机。密文 secret 名见上面「已用 sops 加密入库」。`.sops.yaml` 里只有公钥接收者。
- 快捷键不是未办。`modules/shortcuts.nix` 已提交。默认 `orion.shortcuts.profile = "current"`，此时 `services.keyd.enable` 为 false。改成 `"macos"` 才启用 keyd。toplevel 已求值通过。

### NUR

25 个缺口里，NUR 能安装的有 3 个。其余 22 个仍要自己处理。包都对着这份锁住的 nixos-26.05 看过。

能安装：

- 百度网盘 8.9.7：`nur.repos.freegoxing.baidunetdisk`。和已装版本一致。不要用 `nur.repos.xddxdd.baidunetdisk`，它会把客户端换到仓库自带的 Electron 11.5.0 上。
- 钉钉 9.0.0.261105002：`nur.repos.yakkhini.dingtalk`。和已装版本一致，走调用方的 nixpkgs。
- WPS 365 12.8.2.21176：`nur.repos.novel2430.wpsoffice-365`。版本号和已装的教育版相同，属性名不带 edu。同仓库的 `wpsoffice` 11.1 和 `wpsoffice-cn` 12.1 都更旧，不用。

没有包：alder、crm、udf-http-range-proxy、keepassxc-unlock、verilog-format、xjtu-course-genius、xjtutoolbox、botmux、animeko、华为云会议、Anaconda、Typora 的更新版本。easyconnect 的唯一命中是 zju-connect 的协议枚举，没有深信服客户端。grok-bot 桌面版没有包；`nur.repos.xddxdd.grok-search-rs` 是搜索用的 MCP 服务。

字体和词库：`nur.repos.rewine.ttf-ms-win10`、`nur.repos.chillcicada.ttf-ms-win10`、`nur.repos.chillcicada.ttf-ms-win10-sc-sup`、`nur.repos.DzmingLi.windows-fonts` 都是再分发字体，不是让用户自己提供文件的封装，所以不接入。fcitx5 拼音用户词库是个人文件，NUR 不会有。

秘密不能靠 NUR：Clash 配置、anytls 密钥、rclone webdav、JetBrains 许可证、bots.json、NetworkManager 的 PSK。

这三项还没有写进 flake。要接入再说。

## 再加一台机器

`modules/hardware.nix` 只由 `hosts/orion/default.nix` 导入，里面是这台机器的 btrfs 子卷和 Windows ESP。`orion.boot`、`orion.chinese`、`orion.nix`、`orion.secrets`、`orion.shortcuts` 仍是开关。桌面、用户、网络、服务和软件包模块目前按 Orion 写死，第二台机器要覆盖这些模块，不要直接改 Orion 的磁盘 UUID。

1. 复制 `hosts/example.nix` 为 `hosts/<名字>/default.nix`。
2. 在 `flake.nix` 的 `nixosConfigurations` 里加一条属性，带上 `system`、`hostName` 和 `modules = [ ./hosts/<名字> ]`。
3. 改主机名、文件系统、initrd 和显卡 PCI，不要复用 Orion 的分区 UUID。

用户 jimmywang0417 的 Plasma 布局在 `home/jimmy.nix`，由主机文件导入。另一台机器可以同样导入，也可以不导入。
