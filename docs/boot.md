# GRUB

## 作用

启动菜单沿用本机正在用的 DedSec 主题：VandalByte 的 [dedsec-grub2-theme](https://github.com/VandalByte/dedsec-grub2-theme) `bbfe078386545688727f44897a7fede8af2c6dda`，fuckery、1440p、彩色图标。主题包和每日更新在 nur-packages，nixos-config 只引用。`boot.loader.grub.theme` 指向 flake 输入 `nur-packages` 的 `grub-theme-dedsec`。

同一系统不在顶层出现两次。NixOS 的旧世代仍在子菜单里。另一块 NVMe 上的 Windows 只有一条，链到 ESP `UUID=0AF1-1155` 的 `/EFI/Microsoft/Boot/bootmgfw.efi`。

## 开关和默认值

`orion.boot.enable` 打开后：

- `boot.loader.grub.theme` 默认是 `inputs.nur-packages` 的 `grub-theme-dedsec`
- `boot.loader.grub.useOSProber = false`
- `boot.loader.grub.gfxmodeEfi = "auto"`，`gfxpayloadEfi = "keep"`，对应现场 `GRUB_GFXMODE=auto` 和 `GRUB_GFXPAYLOAD_LINUX=keep`
- `boot.loader.grub.splashImage = null`，不用 NixOS 自带的启动壁纸盖住 DedSec
- `boot.loader.timeout` 由主机设为 10，对应现场 `GRUB_TIMEOUT=10`
- `boot.loader.efi.canTouchEfiVariables` 默认 false
- 不设置 `configurationLimit`，世代数量保持 NixOS 默认，子菜单保留

## 相关文件

- `modules/boot.nix`
- `hosts/orion/default.nix` 里的 `orion.boot.timeout = 10`
- `docs/bootstrap.md` 记下同一主题路径
- 现场 `/etc/default/grub` 的 `GRUB_THEME=/boot/grub/themes/dedsec/theme.txt`
- 现场 `/etc/fstab` 的 ESP `UUID=0AF1-1155`

## 依赖

主题包和每日更新在 nur-packages，nixos-config 只引用。以后真正执行 `nixos-rebuild` 时，安装脚本从这个 store 路径拷到 `/boot/grub/theme`。这次只求值，不跑 `grub-mkconfig`，也不跑 `grub-install`。

主题修订由 nur-packages 每天 16:00 UTC 的更新工作流开 PR。rev 没变就不开。本仓库的 `updates.nix` 不再列这个包。

## 未办或不迁

2026-11-02 14:39 生成的正在使用的 `grub.cfg` 里，顶层把同一系统写了两次。`10_linux` 有一条 `Manjaro Linux`（6.12 在顶层，6.1-rt 在 Advanced options 子菜单）。os-prober 另有一条 Windows Boot Manager。`/etc/grub.d/31_efi_bootnext` 又加了 `Manjaro (EFI BootNext)`（Boot0001，`\EFI\Manjaro\grubx64.efi`，就是这份 GRUB）和 `Windows Boot Manager (EFI BootNext)`（Boot0000，同一份 `bootmgfw.efi`）。它还把多条失效的 `Linux Boot Manager (EFI BootNext)` 放进菜单，那些是别的盘上的 systemd-boot NVRAM。os-prober 没有把这块 btrfs 上的 Manjaro 再报一次。

NixOS 配置不生成 BootNext 项，也不把 Timeshift 快照做成第二套顶层系统。`grub-btrfs` 不迁。
