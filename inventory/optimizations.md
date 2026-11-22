> 原始迁移扫描记录，保留当时的路径与结论。当前实现以模块、[配置覆盖清单](configuration-coverage.json)和[软件版本审计](software-versions.json)为准。

# 迁移时改过的写法

每条都保留原来的功能。桌面布局不在这里改，见 `inventory/plasma-layout.md`。

## mhwd 把核显驱动也拉黑了

`/etc/modprobe.d` 里 mhwd 生成的配置除了 `blacklist nouveau`，还拉黑了 `ttm`、`drm_kms_helper`、`drm`。这会拆掉 Intel 显示。NixOS 的 `hardware.nvidia` 只屏蔽 nouveau。Iris Xe 和 RTX 3060 的 PRIME offload 都还在。

## 混合显卡配了两次

现场同时有 `nvidia-prime` 包和 mhwd 的 xorg 片段。现在只有 `hardware.nvidia.prime.offload`，PCI 为 `PCI:0:2:0` 和 `PCI:1:0:0`。`modesetting.enable` 负责 `nvidia-drm.modeset=1` 和驱动版本够新时的 `nvidia-drm.fbdev=1`。`powerManagement.finegrained` 对应原来的 `NVreg_DynamicPowerManagement=0x02`，`powerManagement.enable` 对应 `NVreg_PreserveVideoMemoryAllocations=1`。

## 休眠参数指向不存在的交换文件

命令行有 `resume=UUID=fd32207f-8a11-48d7-9d04-9316cdb8c265 resume_offset=90187008`，但 `swapon` 为空，`/swapfile` 不存在，fstab 里的 swap 行被注释。已去掉 resume。深睡眠 `mem_sleep_default=deep` 留在 `hosts/orion/default.nix`。`quiet` 和 `udev.log_priority=3` 与 NixOS 默认日志重复，没有再写一遍。

## 输入法环境变量互相打架

`/etc/environment` 把 `XMODIFIERS=@im=fcitx` 写了两次，GTK/Qt/SDL 是 fcitx，`GLFW_IM_MODULE=ibus`。fcitx5 的 profile 本身是干净的：组「默认」，`keyboard-cn` + `pinyin`，没有废弃插件。配置只保留 fcitx5（含 waylandFrontend、GTK、Qt6、中文插件）。GLFW 的 ibus 值不再导出。`kwinrc` 里指向 `/usr/share/applications/org.fcitx.Fcitx5.desktop` 的绝对路径已去掉，避免 Nix 商店路径对不上；Wayland 登录仍由 `i18n.inputMethod.fcitx5` 接管。拼音配置里的云拼音开关随 `pinyin.conf` 一起部署。

## 字体配置叠了好几层

`/etc/fonts/conf.d` 里 wqy、Noto、DejaVu、Droid 各写各的优先级，用户目录没有自己的 fontconfig，`kdeglobals` 也没有指定字体名。现在用 `fonts.fontconfig.defaultFonts` 一条链：无衬线 Noto Sans CJK SC → Noto Sans → Source Sans 3 → DejaVu Sans，衬线和等宽同理，表情用 Noto Color Emoji。轻微 hinting 和抗锯齿还在。文泉驿微米黑仍然安装，但不插到 Noto 前面。

## SDDM 主题写了两个值

`00_manjaro_settings.conf` 是 breath，后面的 `kde_settings.conf` 是 breeze，光标是 `breeze_cursors`。按后加载的文件，实际主题是 breeze，而且 breath 是 Manjaro 包。SDDM 使用 breeze。Plasma 外观包名 `org.manjaro.breath-light.desktop` 仍写在部署的 `kdeglobals` 里，颜色是内联的，所以缺这个包时当前配色还在。

## neofetch 已从 nixpkgs 删除

现场同时装了 neofetch 和 fastfetch。neofetch 上游停更，nixpkgs 已移除。系统信息功能由仍在的 fastfetch 承担。

## 不该在这台 Intel 机器上启用的包

装了 `amd-ucode`，CPU 是 i9-12900H。只开 Intel 微码。`libva-intel-driver` 是旧的 i965，Iris Xe 改用 `intel-media-driver`。`acpid` 和 logind 抢电源事件，电源键/合盖交给 systemd-logind。`ntp` 包和已启用的 `systemd-timesyncd` 重复，只留 timesyncd。

## Manjaro 专用工具

mhwd、pamac、manjaro-*-settings、Manjaro GRUB/Plymouth/SDDM 主题不进配置。对应功能分别是 NixOS 模块、声明式软件列表、GRUB EFI（`useOSProber` 以便以后还能看见 Windows）和 SDDM breeze。

## NetworkManager 的 vpnc 插件已被上游删除

现场装了 `networkmanager-vpnc`。nixpkgs 因上游归档且不安全，删掉了这个包，并建议改用 libreswan。这台机器没有 libreswan 配置，所以不换成另一个协议。OpenVPN、L2TP、OpenConnect 仍然启用。vpnc 这一项记在未覆盖里。

## 防火墙原来是关的

`iptables` 未启用，没有 firewalld/ufw。NixOS 打开防火墙，并放行 KDE Connect 的 1714–1764，避免局域网互传消失。Docker 仍由 NixOS 的 docker 模块处理转发。

## 自动登录不是共享模块里的强制项

现场 SDDM 对 jimmywang0417 自动登录 `plasmax11`。这个行为留在主机文件的 `orion.desktop.autoLogin`，共享模块没有 `mkForce`。另一台机器可以关掉。

## 没有复制的大段 dotfile

Oh My Zsh 主题 powerlevel10k、插件 git、`ls` 到 `lsd` 的别名都在。`thefuck` 已从 nixpkgs 删除（上游停更，且不兼容 Python 3.12）。纠正上一条命令的功能改由 `pay-respects` 承担。约 96KB 的 `~/.p10k.zsh` 向导结果没有整份放进仓库。Clash Verge 的节点和任何隧道地址都没有写入。

## 磁盘

Windows 所在的 nvme0 NTFS 没有写成 fileSystems。nvme1 上未挂载的 NTFS「数据分区」也没有加挂载项。EFI 只按现有 UUID `0AF1-1155` 挂载。`boot.loader.efi.canTouchEfiVariables` 默认 false。本仓库不执行 switch。
