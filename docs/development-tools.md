# 开发与系统维护工具

`home/modules/development/` 按 `nh.nix`、`direnv.nix`、`nix-index.nix` 分别管理
系统构建助手、项目环境和命令索引。工具包均使用全局 unstable；索引输入的 nixpkgs
同样 follows unstable，但预构建数据库不保证与当前 `flake.lock` 的软件版本完全同步。

## nh

`NH_OS_FLAKE` 指向用户目录下可写的
`Git Repositories/nixos-config#orion`。路径通过 Home Manager 的环境变量写入，
空格不会变成多个 shell 参数；`#orion` 明确选择 flake 配置名，而非猜测机器的
`Orion-Laptop` 主机名。

在 NixOS 上使用：

```sh
nh os build
nh os test
nh os switch
```

`build` 构建并显示差异；`test` 激活到当前运行系统但不改默认启动代；`switch` 正式
切换。不会自动更新 lock。移动仓库后应修改 `programs.nh.osFlake`，或给命令传入
新的 flake 路径。未启用 `nh clean` 定时任务，历史保留由原有 NixOS GC 策略统一管理。

## direnv 与 nix-direnv

进入项目时加载对应 `devShell`，离开时撤销环境。Zsh hook 由 Home Manager 注入，
`nix-direnv` 提供缓存并保护该环境的 Nix 依赖；因此活跃项目可能阻止部分依赖被 GC。
不自动下载全局替代工具链，也不改已有的 elan/rustup 默认选择。

此仓库的 `.envrc` 只有 `use flake`。首次使用须在项目目录自行执行：

```sh
direnv allow
```

不会预先信任整个家目录。其他项目应自行提供 `flake.nix` 的 `devShells` 与 `.envrc`；
现有全局开发软件仍保留，项目环境可以逐项接管其特定版本。

## nix-index-database 与 comma

`nix-locate` 使用 flake 固定的预构建数据库，避免本机全量建立索引。例如：

```sh
nix-locate --top-level --whole-name bin/patchelf
, cowsay hello
```

逗号命令让偶尔使用的工具在临时 Nix 环境中运行，不安装进持久用户 profile；有多个
候选包时可能需要选择。数据库随该输入的 lock 更新，不通过未声明的定时下载改写。
遇到索引命中但当前包集找不到对应属性时，应核对锁定版本并更新输入。

Zsh 缺失命令时由 nix-index 给出包提示；pay-respects 以 `--nocnf` 禁用自身的同名
处理器，并通过 `f` 保留显式纠错功能，避免两个处理器互相覆盖。未额外安装独立
`nix-index` 包，使用数据库模块提供的 wrapper。

依据：[nh](https://github.com/nix-community/nh)、
[nix-direnv](https://github.com/nix-community/nix-direnv)、
[nix-index-database](https://github.com/nix-community/nix-index-database)、
[pay-respects](https://github.com/iffse/pay-respects)。
