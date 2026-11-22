# Lean 与 Rust 的半声明式工具链

`home/modules/development/` 独立管理 elan 与 rustup。管理器二进制来自同一锁定的
unstable 包集；编译器在用户激活时由管理器下载，不把下载后的工具链放进 Nix store，
也不声称其版本由 `flake.lock` 固定。

组合入口明确声明：

```nix
orion.development = {
  elan = { enable = true; defaultToolchain = "stable"; };
  rust = { enable = true; defaultToolchain = "stable"; };
};
```

Home Manager 在写入边界之后执行真实的初始化：

```sh
elan toolchain install stable
elan default stable
rustup set profile default
rustup default stable
rustup component add --toolchain stable rustfmt clippy rust-src
```

当前 elan 的 `default` 命令只写默认选择，所以必须显式先安装。Rustup 的
`default stable` 会安装缺失的工具链。工具链下载失败会使对应激活步骤失败，不把
没有安装成功的环境伪装成已就绪；`--dry-run` 通过 Home Manager 的 `run` 包装跳过执行。

设置文件保留可写：`~/.local/share/elan/settings.toml`、
`~/.local/share/rustup/settings.toml`（跟随 `XDG_DATA_HOME`）。Elan 记录
`stable`；rustup 可规范化为 `stable-<host triple>`。项目的 `lean-toolchain`、
`rust-toolchain.toml` 继续生效；管理器数据目录内的 overrides 在更新默认值时保留。

本机旧 `~/.elan`、`~/.rustup` 中的二进制使用 Manjaro 的
`/lib64/ld-linux-x86-64.so.2`。NixOS 下使用独立数据目录，让 Nix 打包的管理器
下载并修补新工具链；不把旧目录直接当作已安装的 NixOS 工具链。旧数据保留不动，
该主机的旧配置没有目录 overrides。迁移其他主机若有手动 overrides，应另外核对；
不要直接拷贝旧编译器二进制。可通过各模块的 `stateDirectory` 选项指定已确认兼容的目录。
目录变量同时提供给登录 shell 与 systemd 用户服务，方便编辑器与后台工具找到相同的安装。
Cargo 缓存与配置继续使用 `~/.cargo`，不把旧的 `~/.cargo/bin` 放到 Nix 代理之前。

不再把独立的 Nix `cargo`、`rustc`、`rustfmt` 同时放进用户 profile；使用 Nix 打包的
rustup 代理，避免覆盖和绕过工具链选择。保留 C/C++ 编译器供本机编译与链接使用。
Rust Analyzer 的服务程序仍由 VS Code 扩展包提供，`rust-src` 由 rustup 安装。

更新已安装工具链仍使用管理器命令，例如 `rustup update stable` 与
`elan toolchain install stable`。激活时确保所选默认渠道与组件，不等于给整个用户目录
做一次无条件清理或升级。首次激活需要能访问相应官方发布服务器。

依据：[elan 4.3 默认选择源码](https://github.com/leanprover/elan/blob/v4.3.0/src/elan-cli/elan_mode.rs#L252)、
[elan 使用说明](https://github.com/leanprover/elan)、
[Rustup 渠道](https://rust-lang.github.io/rustup/concepts/channels.html)。本次修改提供
真实的下载/默认选择步骤，不会在配置求值时下载编译器，也不改当前 Manjaro 用户的工具链。
