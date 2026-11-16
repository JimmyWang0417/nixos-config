# 软件包

## 作用

系统安装的软件在 `modules/packages.nix`。nixos-26.05 里有的属性用 `pkgs`。没有或过旧的属性放进 `orion.packages.unstable`，从 flake 输入 `nixpkgs-unstable` 取。这一路不单给某一个程序。

## 开关和默认值

`orion.packages.unstable` 的类型是包列表，默认 `[]`。Orion 目前有一项：`deepseek-harness` 0.2.2-rc.1（命令 `dsh`）。没有单独的开关。

## 相关文件

- `flake.nix` 的输入 `nixpkgs-unstable`，锁在 `5d2b81a7a3be3e2f832879028e4d60abbf58e9a0`
- `modules/packages.nix`
- `hosts/orion/default.nix`

## 依赖

`deepseek-harness` 的默认沙箱要在 `PATH` 上找到 `bwrap`，所以同一份系统包列表里有 `pkgs.bubblewrap`。模型凭据不入库。

## 未办或不迁

没有装社区插件。NUR 上的 `nur.repos.ryan4yin.dsh` 是 0.2.2-rc.3，另一套 npm 封装，没有改用它。
