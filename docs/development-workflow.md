# 开发环境与提交检查

仓库的开发工具从锁定的 `nixpkgs-unstable` 获取。首次运行会下载工具；不会
构建或激活整套 NixOS，也不需要私有配置的解密密钥。

```sh
nix develop
nix fmt
pre-commit run --all-files
bash tests/eval.sh
nix flake check --no-update-lock-file
```

`nix develop` 安装由 `git-hooks.nix` 生成的本地 pre-commit hook，同时提供
`pre-commit` 和固定版本的检查工具。生成的 `.pre-commit-config.yaml` 是指向
Nix store 的链接，不提交到 Git。`nix fmt` 通过 `treefmt-nix` 运行 Nixfmt、
shfmt 和 Ruff formatter。格式检查失败后先运行 `nix fmt`，检查差异，再重新暂存。

Nix 格式检查覆盖维护中的 `.nix` 文件；Shell 覆盖 `bootstrap/`、`tests/`；
Python 覆盖 `lib/`、`scripts/`、`tests/` 和 `modules/` 中的维护脚本。导入的
桌面偏好、编辑器和插件资源、软件审计 JSON 及密文归档不被批量改写。

Statix 检查 Nix 写法；`statix.toml` 仅关闭四项风格偏好：模块属性分组、空参数
模式、`inherit` 替代建议和 eta reduction。布尔条件、无效或多余表达式等规则
继续启用。Deadnix 检查未使用的绑定，但允许 NixOS/Home Manager 模块参数模式
保留可选参数。Actionlint 检查 GitHub Actions 工作流。这三项检查不自动修改源文件。

GitHub Actions 在推送 master 和 PR 时实际构建格式与静态检查 derivation，
再运行现有配置求值及行为测试。它不会执行 `nixos-rebuild switch`、下载运行时
Lean/Rust 编译器或启动图形会话。求值通过仍不代表 NVIDIA、中文输入法和远程
桌面已在目标 NixOS 硬件上验证。

集成依据：[treefmt-nix](https://github.com/numtide/treefmt-nix)、
[git-hooks.nix](https://github.com/cachix/git-hooks.nix)。
