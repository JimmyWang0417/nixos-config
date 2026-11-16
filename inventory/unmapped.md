# 未覆盖

这些名字没有写进 Nix 模块。原因写在第二列。

| 名称 | 原因 |
| --- | --- |
| panon、latte separator、window-title、org.communia.apptitle | 本地 plasmoid 没有被 appletsrc 引用 |
| WhiteSur 壁纸目录 | appletsrc 没有 Image 路径，约 2.8MB，不入库 |
| WhiteSur Aurorae 主题文件 | kwinrc 仍使用主题名 __aurorae__svg__WhiteSur，nixpkgs 未提供可安装的同名主题包，故只保留名字 |
| org.manjaro.breath-light.desktop | Manjaro 外观包。kdeglobals 里的颜色是内联的 |
| ~/.p10k.zsh | 约 96KB 的向导结果，不整份复制。powerlevel10k 程序已启用 |
| keepass-sync.timer | 用户 timer 调用 rclone。远端路径可能指向私人同步目标，不入库 |
| anytls 用户隧道 | unit 名里带具体地址，不写入仓库 |
| EasyMonitor.service | 深信服 EasyConnect 的专有服务，不复制二进制 |
| aarch64-linux-gnu-gcc | 交叉编译工具链，没有对应的日常功能被服务引用 |
| ac-library | 竞赛头文件库，nixpkgs 无同名包 |
| acpid | 与 systemd-logind 冲突，电源事件交给 logind |
| alder | 未找到对应 nixpkgs 包，也没有启用的服务 |
| amd-ucode | CPU 是 Intel i9-12900H，不安装 AMD 微码 |
| anaconda | Anaconda 安装器，科学计算库已拆到 python3.withPackages |
| animeko-appimage | AUR AppImage，nixpkgs 无此包 |
| antigravity | 专有/AUR 客户端，nixpkgs 无此包 |
| appmenu-gtk-module | 未写入模块；全局菜单部件仍由 Plasma appmenu 提供 |
| aurpublish | AUR 辅助工具 |
| b43-fwcutter | 没有 Broadcom b43 网卡 |
| baidunetdisk-bin | 专有客户端，nixpkgs 无官方包 |
| bibiman-bin | AUR 二进制包 |
| binder_linux-dkms | 未发现对应的容器/安卓服务在运行 |
| botmux-bin | AUR 二进制包，用户服务 botmux 未迁移 |
| cc-switch-bin | AUR 二进制包。图标仍留在任务栏布局里 |
| chatgpt-desktop | 专有客户端 |
| clash-verge-rev-bin | 专有代理。pon/poff 仍指向 127.0.0.1:10808，节点和密钥不入库 |
| claude-code | 专有 CLI，nixpkgs 无同名包 |
| crm | 未找到可对应的 nixpkgs 包 |
| cursor-cli | Cursor CLI 未映射 |
| cursor-early-access-bin | Cursor 客户端未映射 |
| debtap | Arch 专用 |
| dingtalk-bin | 专有客户端 |
| dmraid | 没有 fakeraid |
| easyconnect | 深信服专有 VPN，不复制二进制和 EasyMonitor unit |
| ecryptfs-utils | 没有 ecryptfs 挂载 |
| electron22-bin | 某个 AUR 应用的运行时，不是独立功能 |
| ex-vi-compat | Arch 兼容包 |
| feishu-bin | 专有客户端 |
| github-copilot-app-bin | 专有插件应用 |
| github-copilot-cli | 专有 CLI |
| github-desktop-bin | nixpkgs 未列入本配置 |
| grok-bot-bin | 专有客户端 |
| grok-build | 专有构建工具 |
| grub-btrfs | Arch/mkinitcpio 的 grub-btrfs，NixOS 不使用这套 hook |
| grub-theme-manjaro | Manjaro GRUB 主题 |
| gtk3 | 由 Plasma/GTK 依赖带入，不单列 Arch 包名 |
| heroic-games-launcher | 未写入系统包 |
| hexo-cli | Node 全局 CLI，未写入 |
| huaweicloudmeeting-bin | 专有客户端 |
| install-grub | Manjaro 辅助脚本，引导由 boot.loader.grub 表达 |
| kazumi-bin | AUR 二进制包 |
| keepassxc-unlock | 第三方自动解锁辅助，不迁移 |
| lemon-lime | AUR 包。任务栏图标保留，软件本身未映射 |
| lib32-libva-intel-driver | 旧 i965 32 位驱动，核显改用 intel-media-driver |
| libpamac-flatpak-plugin | Manjaro pamac |
| libva-intel-driver | 旧 i965 驱动，Iris Xe 改用 intel-media-driver |
| linuxqq | 专有客户端 |
| logiops | 未写入。没有看到已启用的 logiops 服务 |
| logisim-evolution-bin | AUR 二进制包 |
| logrotate | NixOS 使用 journald，不迁移这条 logrotate 配置 |
| manjaro-alsa | Manjaro 元包，ALSA 由 PipeWire 承担 |
| manjaro-application-utility | Manjaro 专用 |
| manjaro-browser-settings | Manjaro 专用 |
| manjaro-gstreamer | Manjaro 元包，GStreamer 插件已单列 |
| manjaro-hello | Manjaro 专用 |
| manjaro-kde-settings | Manjaro 主题元包。布局用扫描到的 rc，不用这个包 |
| manjaro-modem | Manjaro 元包，ModemManager 由 networking.modemmanager 承担 |
| manjaro-pipewire | Manjaro 元包，音频由 services.pipewire 承担 |
| manjaro-printer | Manjaro 元包，打印由 services.printing 承担 |
| manjaro-release | 发行版标识 |
| manjaro-settings-manager-knotifier | Manjaro 专用 |
| manjaro-system | Manjaro 专用 |
| manjaro-zsh-config | Manjaro zsh 片段。改为 home-manager 的 oh-my-zsh 与 powerlevel10k |
| mhwd | Manjaro 硬件探测，由 nixos-hardware 与 hardware.nvidia 替代 |
| mhwd-db | Manjaro 硬件数据库 |
| mkinitcpio-openswap | Arch initramfs hook，且没有 swap |
| motrix-bin | AUR 二进制包 |
| msedgedriver-stable-bin | 与 Edge 版本锁定的驱动，未写入 |
| mtpfs | 未写入。手机访问仍可由 Plasma 设备通知部件提供 |
| neofetch | 上游停更已从 nixpkgs 删除，功能由 fastfetch 承担 |
| networkmanager-vpnc | nixpkgs 因上游归档且不安全已删除，不改成 libreswan |
| nss-mdns | avahi 服务未启用，不打开 nss-mdns |
| ntp | NTP 由 systemd-timesyncd 承担 |
| numlockx | 没有看到已启用的数字锁定配置 |
| ocs-url | 商店链接助手，未写入 |
| opencode | 未写入 |
| pacman-contrib | Arch 专用 |
| pamac-cli | Manjaro 软件中心，由 Nix 声明式配置替代 |
| pamac-gtk3 | Manjaro 软件中心 |
| pamac-tray-icon-plasma | Manjaro 托盘图标。布局收藏夹里仍保留 pamac 的 desktop id |
| paru | AUR helper |
| perl-file-mimeinfo | 未写入 |
| piliplus-bin | AUR 二进制包 |
| playwright | 测试浏览器驱动未写入，geckodriver 已映射 |
| plymouth | 服务未启用，不打开开机动画 |
| plymouth-kcm | Plymouth 未启用 |
| plymouth-theme-manjaro | Manjaro 开机动画 |
| poppler-data | 未单列 poppler_data |
| python-markitdown-git | git 快照，无稳定 nixpkgs 属性 |
| python-pysmbc | nixpkgs 无对应属性 |
| python-pytorch-opt-cuda | CUDA 轮子与本机驱动绑定，不写入通用配置 |
| s-nail | 未写入 |
| sddm-breath-theme | Manjaro breath 主题。SDDM 采用后加载的 breeze |
| sunshine-bin | 未写入 |
| sysfsutils | 未写入 |
| timeshift-autosnap-manjaro | Manjaro hook |
| ttf-droid | 不再单独安装，避免和 Noto 的 fontconfig 抢优先级 |
| ttf-indic-otf | nixpkgs 无同名包，未放入字体链 |
| ttf-ms-win10-auto | 专有字体，不入库 |
| typora-free-with-plugin | 专有/AUR 编辑器 |
| typstyle | 未写入 |
| udev-usb-sync | Arch 专用 udev 规则 |
| update-grub | Manjaro 脚本，引导由 boot.loader.grub 表达 |
| usb_modeswitch | 不单列。ModemManager 模块自带所需依赖 |
| ventoy | 未写入 |
| verilog-format-git | git 快照 |
| wechat-bin | 专有客户端 |
| wemeet-bin | 专有客户端 |
| wps-office-365-edu | 专有办公套件 |
| wps-office-365-edu-fonts | 专有字体 |
| xf86-input-elographics | 未使用的 X 输入驱动，触摸板走 libinput |
| xf86-input-evdev | 未使用的 X 输入驱动 |
| xf86-input-void | 未使用的 X 输入驱动 |
| xjtu-course-genius | AUR/本地工具 |
| xjtutoolbox-bin | AUR 二进制包 |
| xorg-mkfontscale | 字体索引由 NixOS fontconfig 生成 |
| xorg-twm | 不启用 twm 会话 |
| xorg-xinit | 不用 startx，会话由 SDDM 启动 |
| xorg-xkill | 没有单独安装。Plasma 会话不依赖这个小工具 |
