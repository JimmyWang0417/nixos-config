# 引导

## 作用

`bootstrap/install.sh` 在已经装好的 NixOS 上、flake 还不能用的时候运行。它为这一次命令打开 `nix-command` 和 `flakes`，并把这两项追加进 `/etc/nix/nix.conf`。然后执行 `nixos-rebuild switch --flake <仓库>#orion`。flake 能用之后仍然用这条命令。

## 开关和默认值

目标固定是 `orion`。不带参数时，只有 `/etc/hostname` 为 `Orion-Laptop` 才切换。其他主机名在写好 nix.conf 后停住，并打印本来要执行的命令。`--force` 让其他主机名也切换。

## 相关文件

- `bootstrap/install.sh`
- `flake.nix` 的 `nixosConfigurations.orion`
- `modules/hardware.nix`
- `modules/nix-settings.nix` 在切换成功后把 `experimental-features` 写进系统配置
- 本机 GRUB 主题留在 `/boot/grub/themes/dedsec`。`boot.loader.grub.theme` 指向这个目录，文件不进仓库。说明在 `docs/boot.md`。

## 依赖

PATH 上要有 `nixos-rebuild`。脚本不分区，也不安装 NixOS。普通用户运行；sudo 只用于写入 `/etc/nix/nix.conf` 和 `nixos-rebuild`。

## 未办或不迁

不把 `/etc/nixos/hardware-configuration.nix` 拷进仓库。仓库里的硬件文件仍是 Orion 笔记本时，另一台机器要自己把生成的文件拷到 `hosts/orion` 再切换。
