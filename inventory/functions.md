# 功能对照
每一行的最后一列是提供该功能的文件。软件包按 pacman 显式安装名列出。
## 主机
| 功能 | 提供位置 |
| --- | --- |
| 主机名 Orion-Laptop | hosts/orion/default.nix |
| flake 属性 nixosConfigurations.orion | flake.nix |
| 再加一台机器的模板 | hosts/example.nix |
| Intel 微码与笔记本平台 | hosts/orion/default.nix |
| btrfs 子卷 @、@home、@cache、@log | hosts/orion/default.nix |
| EFI UUID 0AF1-1155，不格式化 Windows NTFS | hosts/orion/default.nix |
| 不挂载未使用的 NTFS 数据分区 | hosts/orion/default.nix |
| 无 swap，不设置 resume | hosts/orion/default.nix |
| mem_sleep_default=deep | hosts/orion/default.nix |
| GRUB EFI，canTouchEfiVariables 默认 false | modules/boot.nix |
| NVIDIA PRIME offload，open 模块 | modules/nvidia.nix |
| 默认会话 plasmax11，Wayland 会话 plasma 仍安装 | modules/desktop.nix |
| SDDM breeze 与自动登录 | hosts/orion/default.nix |
| fcitx5 中文输入 | modules/chinese.nix |
| 一条 CJK fontconfig 回退链 | modules/chinese.nix |
| 时区 Asia/Shanghai、locale zh_CN.UTF-8、X11 布局 cn、timesyncd | modules/locale.nix |
| 用户 jimmywang0417 | modules/users.nix |
| Docker | modules/services.nix |
| 打印、bluetooth、pipewire、cron、fstrim、fwupd、ModemManager、bolt | modules/services.nix |
| NetworkManager 与 KDE Connect 端口 | modules/networking.nix |
| 中科大 Nix 镜像 | modules/nix-settings.nix |
| sops-nix 接口，仓库内无密文 | modules/secrets.nix |

## 桌面部件与主题

| 功能 | 提供位置 |
| --- | --- |
| Kickoff 开始菜单 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 图标任务栏 icontasks | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 底部短 spacer | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| CPU 饼图 systemmonitor | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 模拟时钟 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 回收站 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 全局菜单 appmenu | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 顶部 spacer | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| marginsseparator | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 显示桌面 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 桌面分页 pager | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 系统托盘 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 数字时钟 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 托盘：媒体、KDE Connect、显示、摄像头、剪贴板、设备、键盘、输入法、通知、打印、音量、天气、电池、蓝牙、亮度、网络 | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 两个 folder 桌面与活动「默认」 | home/plasma/kactivitymanagerdrc |
| 壁纸插件 org.kde.image | home/plasma/plasma-org.kde.plasma.desktop-appletsrc |
| 图标主题 Tela | home/plasma/kdeglobals |
| Aurorae 装饰名 WhiteSur | home/plasma/kwinrc |
| 内联配色与缩放 1.5 | home/plasma/kdeglobals |
| 虚拟桌面与平铺 | home/plasma/kwinrc |
| 输出布局 eDP-1 / HDMI-A-1 / X11-0 | home/plasma/kwinoutputconfig.json |
| 锁屏 30 秒 | home/plasma/kscreenlockerrc |
| 触摸板自然滚动 | home/plasma/kcminputrc |
| fcitx5 拼音 profile | home/fcitx5/profile |
| 拼音云输入开关 | home/fcitx5/conf/pinyin.conf |
| Oh My Zsh、powerlevel10k、lsd、pon/poff | home/jimmy.nix |

## 已映射的 pacman 包

| 功能 | 提供位置 |
| --- | --- |
| acpi → pkgs.acpi | modules/packages.nix |
| adobe-source-sans-fonts → source-sans-pro | modules/chinese.nix |
| alsa-firmware → pkgs.alsa-firmware | modules/packages.nix |
| alsa-utils → pkgs.alsa-utils | modules/packages.nix |
| ark → kdePackages.ark | modules/desktop.nix |
| audiocd-kio → kdePackages.audiocd-kio | modules/desktop.nix |
| avahi → pkgs.avahi，服务未启用，与现在一致 | modules/packages.nix |
| base → NixOS 系统闭合 | modules/packages.nix |
| base-devel → gcc、gnumake、pkg-config | modules/packages.nix |
| bash-language-server → pkgs.bash-language-server | modules/packages.nix |
| biber → texlive.combined.scheme-full | modules/packages.nix |
| bluedevil → plasma6.enable | modules/desktop.nix |
| breeze-gtk → plasma6.enable | modules/desktop.nix |
| breeze5 → Plasma 6 Breeze 覆盖 Qt 主题 | modules/desktop.nix |
| btop → pkgs.btop | modules/packages.nix |
| btrfs-progs → pkgs.btrfs-progs | modules/packages.nix |
| cmake → pkgs.cmake | modules/packages.nix |
| compsize → pkgs.compsize | modules/packages.nix |
| cpupower → linuxPackages.cpupower | modules/packages.nix |
| cronie → services.cron | modules/services.nix |
| cryptsetup → pkgs.cryptsetup | modules/packages.nix |
| ctags → universal-ctags | modules/packages.nix |
| cython → python3Packages.cython | modules/packages.nix |
| device-mapper → lvm2 | modules/packages.nix |
| diffutils → pkgs.diffutils | modules/packages.nix |
| discord → pkgs.discord | modules/packages.nix |
| dmidecode → pkgs.dmidecode | modules/packages.nix |
| dnsmasq → pkgs.dnsmasq，不启用独立服务 | modules/packages.nix |
| docker → virtualisation.docker | modules/services.nix |
| dolphin → kdePackages.dolphin | modules/desktop.nix |
| dolphin-plugins → kdePackages.dolphin-plugins | modules/desktop.nix |
| dosfstools → pkgs.dosfstools | modules/packages.nix |
| e2fsprogs → pkgs.e2fsprogs | modules/packages.nix |
| efibootmgr → pkgs.efibootmgr | modules/packages.nix |
| elisa → kdePackages.elisa | modules/desktop.nix |
| exfatprogs → pkgs.exfatprogs | modules/packages.nix |
| f2fs-tools → pkgs.f2fs-tools | modules/packages.nix |
| fastfetch → pkgs.fastfetch | modules/packages.nix |
| fcitx5 → i18n.inputMethod.fcitx5 | modules/chinese.nix |
| fcitx5-chinese-addons → qt6Packages.fcitx5-chinese-addons | modules/chinese.nix |
| fcitx5-configtool → qt6Packages.fcitx5-configtool | modules/chinese.nix |
| fcitx5-gtk → fcitx5-gtk | modules/chinese.nix |
| fcitx5-qt → qt6Packages.fcitx5-qt | modules/chinese.nix |
| ffmpeg → pkgs.ffmpeg | modules/packages.nix |
| ffmpegthumbs → kdePackages.ffmpegthumbs | modules/desktop.nix |
| filelight → kdePackages.filelight | modules/desktop.nix |
| firefox → pkgs.firefox | modules/packages.nix |
| firefox-i18n-zh-cn → i18n.defaultLocale zh_CN.UTF-8 | modules/locale.nix |
| fwupd → services.fwupd | modules/services.nix |
| fzf → pkgs.fzf | modules/packages.nix |
| gcc-fortran → gfortran | modules/packages.nix |
| gdb → pkgs.gdb | modules/packages.nix |
| geckodriver → pkgs.geckodriver | modules/packages.nix |
| git-lfs → pkgs.git-lfs | modules/packages.nix |
| github-cli → pkgs.gh | modules/packages.nix |
| glibc-locales → i18n.supportedLocales | modules/locale.nix |
| gnome-themes-extra → pkgs.gnome-themes-extra | modules/packages.nix |
| google-chrome → pkgs.google-chrome | modules/packages.nix |
| grub → boot.loader.grub | modules/boot.nix |
| gst-libav → gst_all_1.gst-libav | modules/packages.nix |
| gst-plugins-bad → gst_all_1.gst-plugins-bad | modules/packages.nix |
| gst-plugins-base → gst_all_1.gst-plugins-base | modules/packages.nix |
| gst-plugins-good → gst_all_1.gst-plugins-good | modules/packages.nix |
| gst-plugins-ugly → gst_all_1.gst-plugins-ugly | modules/packages.nix |
| gwenview → kdePackages.gwenview | modules/desktop.nix |
| helix → pkgs.helix | modules/packages.nix |
| htop → pkgs.htop | modules/packages.nix |
| inetutils → pkgs.inetutils | modules/packages.nix |
| intel-ucode → hardware.cpu.intel.updateMicrocode | hosts/orion/default.nix |
| intellij-idea-ultimate-edition → jetbrains.idea | modules/packages.nix |
| inxi → pkgs.inxi | modules/packages.nix |
| iverilog → pkgs.iverilog | modules/packages.nix |
| jdk-openjdk → pkgs.jdk | modules/packages.nix |
| jfsutils → pkgs.jfsutils | modules/packages.nix |
| kaccounts-providers → kdePackages.kaccounts-providers | modules/desktop.nix |
| kamera → kdePackages.kamera | modules/desktop.nix |
| kate → kdePackages.kate | modules/desktop.nix |
| kcalc → kdePackages.kcalc | modules/desktop.nix |
| kde-gtk-config → plasma6.enable | modules/desktop.nix |
| kdeconnect → kdePackages.kdeconnect-kde | modules/desktop.nix |
| kdegraphics-thumbnailers → kdePackages.kdegraphics-thumbnailers | modules/desktop.nix |
| kdenetwork-filesharing → kdePackages.kdenetwork-filesharing | modules/desktop.nix |
| kdeplasma-addons → plasma6 与桌面部件依赖 | modules/desktop.nix |
| keditbookmarks → kdePackages.keditbookmarks | modules/desktop.nix |
| keepassxc → pkgs.keepassxc | modules/packages.nix |
| kfind → kdePackages.kfind | modules/desktop.nix |
| kgamma → kdePackages.kgamma | modules/desktop.nix |
| khelpcenter → kdePackages.khelpcenter | modules/desktop.nix |
| kimageformats → kdePackages.kimageformats | modules/desktop.nix |
| kinfocenter → kdePackages.kinfocenter | modules/desktop.nix |
| kio-extras → kdePackages.kio-extras | modules/desktop.nix |
| kmenuedit → kdePackages.kmenuedit | modules/desktop.nix |
| konsole → kdePackages.konsole | modules/desktop.nix |
| kscreen → plasma6.enable | modules/desktop.nix |
| kscreenlocker → plasma6.enable | modules/desktop.nix |
| ksshaskpass → plasma6.enable | modules/desktop.nix |
| ksystemlog → kdePackages.ksystemlog | modules/desktop.nix |
| kwallet-pam → plasma6.enable | modules/desktop.nix |
| kwalletmanager → kdePackages.kwalletmanager | modules/desktop.nix |
| kwayland-integration → plasma6.enable | modules/desktop.nix |
| kwin → plasma6.enable | modules/desktop.nix |
| kwrited → plasma6.enable | modules/desktop.nix |
| less → pkgs.less | modules/packages.nix |
| lib32-libcanberra → PipeWire/Steam 32 位栈 | modules/packages.nix |
| lib32-mesa → hardware.graphics.enable32Bit | modules/nvidia.nix |
| lib32-mesa-utils → hardware.graphics.enable32Bit | modules/nvidia.nix |
| lib32-nvidia-utils → hardware.nvidia + enable32Bit | modules/nvidia.nix |
| libcanberra → pkgs.libcanberra | modules/packages.nix |
| libdvdcss → pkgs.libdvdcss | modules/packages.nix |
| libreoffice-fresh-zh-cn → pkgs.libreoffice + zh_CN | modules/packages.nix |
| libxnvctrl → hardware.nvidia.nvidiaSettings | modules/nvidia.nix |
| linux-firmware → hardware.enableRedistributableFirmware | hosts/orion/default.nix |
| linux612 → linuxPackages_6_12 | hosts/orion/default.nix |
| linux612-headers → linuxPackages_6_12 | hosts/orion/default.nix |
| linux612-nvidia-open → hardware.nvidia.open | modules/nvidia.nix |
| lsd → pkgs.lsd | modules/packages.nix |
| lvm2 → pkgs.lvm2 | modules/packages.nix |
| man-db → pkgs.man | modules/packages.nix |
| man-pages → pkgs.man-pages | modules/packages.nix |
| mariadb → pkgs.mariadb，不启用服务 | modules/packages.nix |
| marksman → pkgs.marksman | modules/packages.nix |
| mdadm → pkgs.mdadm | modules/packages.nix |
| memtest86+ → pkgs.memtest86plus | modules/packages.nix |
| memtest86+-efi → pkgs.memtest86plus | modules/packages.nix |
| mesa-utils → pkgs.mesa-demos | modules/packages.nix |
| micro → pkgs.micro | modules/packages.nix |
| microsoft-edge-stable-bin → pkgs.microsoft-edge | modules/packages.nix |
| milou → plasma6.enable | modules/desktop.nix |
| modemmanager → networking.modemmanager | modules/services.nix |
| nano → pkgs.nano | modules/packages.nix |
| nano-syntax-highlighting → pkgs.nano | modules/packages.nix |
| neovim → pkgs.neovim | modules/packages.nix |
| networkmanager → networking.networkmanager | modules/networking.nix |
| networkmanager-l2tp → networkmanager-l2tp | modules/networking.nix |
| networkmanager-openconnect → networkmanager-openconnect | modules/networking.nix |
| networkmanager-openvpn → networkmanager-openvpn | modules/networking.nix |
| nfs-utils → pkgs.nfs-utils，不启用服务 | modules/packages.nix |
| nodejs → pkgs.nodejs | modules/packages.nix |
| noto-fonts → noto-fonts | modules/chinese.nix |
| noto-fonts-cjk → noto-fonts-cjk-sans 与 serif | modules/chinese.nix |
| noto-fonts-emoji → noto-fonts-color-emoji | modules/chinese.nix |
| ntfs-3g → pkgs.ntfs3g | modules/packages.nix |
| nvidia-prime → hardware.nvidia.prime.offload | modules/nvidia.nix |
| nvidia-settings → hardware.nvidia.nvidiaSettings | modules/nvidia.nix |
| nvidia-utils → hardware.nvidia | modules/nvidia.nix |
| obs-studio → pkgs.obs-studio | modules/packages.nix |
| obsidian → pkgs.obsidian | modules/packages.nix |
| okular → kdePackages.okular | modules/desktop.nix |
| openblas → pkgs.openblas | modules/packages.nix |
| openrgb → pkgs.openrgb | modules/packages.nix |
| openssh → pkgs.openssh，不启用 sshd | modules/packages.nix |
| os-prober → useOSProber 关闭；Windows 一条 chainloader | modules/boot.nix |
| p7zip-natspec → pkgs.p7zip | modules/packages.nix |
| pandoc-cli → pkgs.pandoc | modules/packages.nix |
| papirus-icon-theme → pkgs.papirus-icon-theme | modules/packages.nix |
| perl → python/系统 perl，若未单列则见未覆盖 | modules/packages.nix |
| phonon-qt6-vlc → kdePackages.phonon-vlc | modules/desktop.nix |
| plasma-browser-integration → kdePackages.plasma-browser-integration | modules/desktop.nix |
| plasma-desktop → services.desktopManager.plasma6 | modules/desktop.nix |
| plasma-nm → plasma6.enable | modules/desktop.nix |
| plasma-pa → plasma6.enable | modules/desktop.nix |
| plasma-systemmonitor → kdePackages.plasma-systemmonitor | modules/desktop.nix |
| plasma-thunderbolt → kdePackages.plasma-thunderbolt | modules/desktop.nix |
| plasma-workspace → plasma6.enable | modules/desktop.nix |
| plasma-workspace-wallpapers → kdePackages.plasma-workspace-wallpapers | modules/desktop.nix |
| power-profiles-daemon → plasma6 默认打开 | modules/desktop.nix |
| powerdevil → plasma6.enable | modules/desktop.nix |
| powertop → pkgs.powertop | modules/packages.nix |
| print-manager → kdePackages.print-manager | modules/desktop.nix |
| proxychains-ng → pkgs.proxychains | modules/packages.nix |
| pycharm → jetbrains.pycharm | modules/packages.nix |
| python-fastapi → python3Packages.fastapi | modules/packages.nix |
| python-matplotlib → python3Packages.matplotlib | modules/packages.nix |
| python-pillow → python3Packages.pillow | modules/packages.nix |
| python-pip → python3.withPackages pip | modules/packages.nix |
| python-pipx → pkgs.pipx | modules/packages.nix |
| python-pyqt5 → python3Packages.pyqt5 | modules/packages.nix |
| python-reportlab → python3Packages.reportlab | modules/packages.nix |
| python-scikit-learn → python3Packages.scikit-learn | modules/packages.nix |
| python-scipy → python3Packages.scipy | modules/packages.nix |
| python-seaborn → python3Packages.seaborn | modules/packages.nix |
| qt6-imageformats → Plasma/Qt6 依赖 | modules/desktop.nix |
| qt6-virtualkeyboard → qt6.qtvirtualkeyboard | modules/desktop.nix |
| ranger → pkgs.ranger | modules/packages.nix |
| rclone → pkgs.rclone | modules/packages.nix |
| rsync → pkgs.rsync | modules/packages.nix |
| samba → pkgs.samba，不启用服务 | modules/packages.nix |
| sbctl → pkgs.sbctl，Secure Boot 保持关闭 | modules/packages.nix |
| sddm → services.displayManager.sddm | modules/desktop.nix |
| sddm-kcm → kdePackages.sddm-kcm | modules/desktop.nix |
| shfmt → pkgs.shfmt | modules/packages.nix |
| skanlite → kdePackages.skanlite | modules/desktop.nix |
| sof-firmware → hardware.firmware | hosts/orion/default.nix |
| spectacle → kdePackages.spectacle | modules/desktop.nix |
| sshfs → pkgs.sshfs | modules/packages.nix |
| steam → programs.steam | modules/packages.nix |
| sudo → users.users.wheel | modules/users.nix |
| system-config-printer → pkgs.system-config-printer | modules/packages.nix |
| systemsettings → plasma6.enable | modules/desktop.nix |
| telegram-desktop → pkgs.telegram-desktop | modules/packages.nix |
| terminus-font → terminus_font | modules/chinese.nix |
| texinfo → pkgs.texinfo | modules/packages.nix |
| texlive-basic → texlive.combined.scheme-full | modules/packages.nix |
| texlive-bibtexextra → texlive.combined.scheme-full | modules/packages.nix |
| texlive-binextra → texlive.combined.scheme-full | modules/packages.nix |
| texlive-fontsextra → texlive.combined.scheme-full | modules/packages.nix |
| texlive-formatsextra → texlive.combined.scheme-full | modules/packages.nix |
| texlive-langchinese → texlive.combined.scheme-full | modules/packages.nix |
| texlive-langjapanese → texlive.combined.scheme-full | modules/packages.nix |
| texlive-langkorean → texlive.combined.scheme-full | modules/packages.nix |
| texlive-langother → texlive.combined.scheme-full | modules/packages.nix |
| texlive-latexextra → texlive.combined.scheme-full | modules/packages.nix |
| texlive-mathscience → texlive.combined.scheme-full | modules/packages.nix |
| texlive-meta → texlive.combined.scheme-full | modules/packages.nix |
| texlive-pictures → texlive.combined.scheme-full | modules/packages.nix |
| texlive-publishers → texlive.combined.scheme-full | modules/packages.nix |
| thefuck → pay-respects 替代 | home/jimmy.nix |
| timeshift → pkgs.timeshift | modules/packages.nix |
| tokei → pkgs.tokei | modules/packages.nix |
| ttf-dejavu → dejavu_fonts | modules/chinese.nix |
| ttf-inconsolata → inconsolata | modules/chinese.nix |
| ttf-liberation → liberation_ttf | modules/chinese.nix |
| typst → pkgs.typst | modules/packages.nix |
| udiskie → pkgs.udiskie | modules/packages.nix |
| udisks2 → plasma6 / udisks2 | modules/desktop.nix |
| unarchiver → pkgs.unar | modules/packages.nix |
| unzip → pkgs.unzip | modules/packages.nix |
| usbutils → pkgs.usbutils | modules/packages.nix |
| visual-studio-code-bin → pkgs.vscode | modules/packages.nix |
| vlc → pkgs.vlc | modules/packages.nix |
| wget → pkgs.wget | modules/packages.nix |
| which → pkgs.which | modules/packages.nix |
| wireless-regdb → linux-firmware | hosts/orion/default.nix |
| wpa_supplicant → NetworkManager wifi.backend | modules/networking.nix |
| wqy-microhei → wqy_microhei | modules/chinese.nix |
| xdg-desktop-portal-kde → plasma6.enable | modules/desktop.nix |
| xdg-user-dirs → xdg.userDirs | home/jimmy.nix |
| xdg-utils → plasma6 / xdg | modules/desktop.nix |
| xf86-input-libinput → services.libinput | modules/desktop.nix |
| xfsprogs → pkgs.xfsprogs | modules/packages.nix |
| xmake → pkgs.xmake | modules/packages.nix |
| xorg-server → services.xserver.enable | modules/desktop.nix |
| xterm → pkgs.xterm | modules/packages.nix |
| yakuake → kdePackages.yakuake | modules/desktop.nix |
