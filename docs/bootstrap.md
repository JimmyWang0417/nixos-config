# 引导

## 作用

`bootstrap/install.sh` 在已经装好的 NixOS 上、flake 还不能用的时候运行。它为这一次命令打开 `nix-command` 和 `flakes`，并把这两项追加进 `/etc/nix/nix.conf`。二进制缓存按中科大、清华、官方这个顺序写进本次命令的 `NIX_CONFIG`，并传给 `nixos-rebuild` 的 `--accept-flake-config` 和 `--option substituters`。公钥只通过 `extra-trusted-public-keys` 追加 `cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=`，不替换 Nix 原来信任的钥匙。`nix.conf` 里还没有中科大地址时，同样两行会追加进去。然后执行 `nixos-rebuild switch --flake <仓库>#orion`。flake 能用之后仍然用这条命令。

flake 输入仍是锁住的 GitHub 修订。这里只改二进制缓存，不把 nixpkgs 地址换成镜像。

## 开关和默认值

目标固定是 `orion`。不带参数时，只有 `/etc/hostname` 为 `Orion-Laptop` 才切换。其他主机名在写好 nix.conf 后停住，并打印本来要执行的命令。`--force` 让其他主机名也切换。

## 相关文件

- `bootstrap/install.sh`
- `flake.nix` 的 `nixosConfigurations.orion`
- `modules/hardware.nix`
- `modules/nix-settings.nix` 在切换成功后把 `experimental-features` 写进系统配置，并给出与 `flake.nix` 的 `nixConfig` 相同的 substituters
- `modules/nix-download.nix` 在 `orion.nix.chinaMirrors.enable` 打开时把这份 substituters 写进 `nix.settings`
- GRUB 主题来自 flake 输入 `nur-packages` 的 `grub-theme-dedsec`。主题包和每日更新在 nur-packages，nixos-config 只引用。说明在 `docs/boot.md`。

## 依赖

PATH 上要有 `nixos-rebuild`。脚本不分区，也不安装 NixOS。普通用户运行；sudo 只用于写入 `/etc/nix/nix.conf` 和 `nixos-rebuild`。

## 未办或不迁

不把 `/etc/nixos/hardware-configuration.nix` 拷进仓库。当前硬件文件是主机 `orion`（Orion-Laptop）的；再加一台机器是新的主机文件，不要写进 `hosts/orion`。
