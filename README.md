# Orion NixOS 配置

这份 flake 描述 Orion-Laptop（HP OMEN 16）的 NixOS 配置：Intel/NVIDIA PRIME offload、btrfs、与 Windows 共用的 ESP、Plasma Wayland，以及供 ToDesk 使用的 Xfce X11。当前开发主机仍运行 Manjaro；仓库验证不会安装或激活 NixOS，也不会修改磁盘、引导或正在使用的桌面。

## 软件来源

- 系统模块、全部 nixpkgs 软件、Home Manager、NUR 构建依赖和开发环境统一使用锁定的 `nixos-unstable`。
- stable 输入 `nixpkgs` 和显式 `pkgsStable` 接口保留，当前功能不从中安装软件。
- 2026-11-22 核实官方 `nixos-26.11` 与 Home Manager `release-26.11` 尚不存在，因此使用 26.11 开发线和 Home Manager master。正式分支可用后再更新保留的 stable 输入。
- Lean/Rust 工具链按用户要求使用 [半声明式管理](docs/toolchains.md)：管理器来自 unstable，激活时下载并写入默认 stable，编译器版本由 elan/rustup 管理。
- 自定义 NUR 配方保留原有功能；其上游版本由各配方维护，不会因为切换 nixpkgs 自动更新。
- `system.stateVersion` 与 `home.stateVersion` 保持 `26.05`；它们控制兼容行为，不是升级开关。

[迁移评估与软件版本](docs/unstable-migration.md)记录核对方法、逐项官方依据、改善和仍有差距的包。[配置覆盖清单](inventory/configuration-coverage.json)区分已经声明的偏好、桌面集成、系统组件和使用包默认设置的项目；安装包不等于账号已登录或个人状态全部声明化。

## 配置结构

[模块结构](docs/architecture.md)说明细粒度目录与扩展方式：

- `hosts/orion/`：主机名、PCI 地址、内核选择、挂载 UUID、功能组合。
- `modules/core/`、`hardware/`、`desktop/`、`network/`、`services/`：各系统功能。
- `modules/packages/`：纯软件清单、兼容策略、浏览器与游戏集成。
- `modules/programs/dsh/`：DSH 选项、协调逻辑及 13 组插件，保留现有 38 个选择。
- `home/jimmy.nix`：用户身份和模块组合。
- `home/modules/apps/`、`editors/`、`shell/`、`desktop/`：各应用、编辑器和桌面配置。
- `home/fcitx5/`、`home/modules/private/`、`lib/`：输入法偏好与运行时私有数据初始化。

主机事实不放进通用包清单；应用配置、安装包和用户状态分别表达。各级入口显式导入文件，新模块也需要加入 Git 才能被 Git flake 看见。

## 桌面与中文输入

默认登录 Plasma Wayland（`plasma`），另提供 Xfce X11（`xfce`）。Plasma 6.8 已退役 X11；需要 ToDesk 控制这台机器时，应在登录界面选择 Xfce。SDDM 欢迎界面仍使用 X11，自动登录进入默认 Plasma 会话。

[Xfce 外观](docs/xfce.md)沿用现有 WhiteSur 浅色、绿色强调色、Tela 图标、WhiteSur 壁纸及上下双面板。主题、面板、壁纸、快捷键分别管理，不覆盖 Plasma 外观。

[中文输入法](docs/input-method.md)使用同一套 fcitx5：KWin 启动 Wayland 输入法，Xfce 使用独立 X11 环境和自启动。旧的全局 GTK/Qt/SDL 强制变量在 Wayland 清理，VS Code 使用上游包装器的原生 Wayland IME 参数。用户词库仅在缺失时从密文恢复，保留后续学习结果。

## 编辑器与应用配置

[VS Code](docs/vscode.md)已有的主题、插件偏好和快捷键均已核对迁入，并补齐中文界面、HDL 格式化/编译、C/C++、Rust、中文 LaTeX 及 Java 路径。32 个当前可从 nixpkgs 声明的扩展纳入模块，其余本机扩展的限制逐项列在文档中。Python 环境和 npm 依赖继续由项目选择。

Neovim 与 ranger 保留原有配置和插件引导。Konsole、Dolphin、Kate、btop、VLC、OBS、Discord、Heroic 的安全公开偏好各自成模块，只在目标文件缺失时初始化；不复制最近文件、播放历史、账号缓存或私有安装路径。Shell 保留原 Powerlevel10k 配置，`pon` 与 Nix 下载统一使用 Clash mixed 代理 `127.0.0.1:7897`。

[DSH](docs/dsh.md)的插件分组、安装协调和更新机制独立。该主机没有可迁移的 DSH 运行目录，因此没有编造 provider、MCP 账号或个人插件设置。

## 私有配置

[密文说明](secrets/README.md)列出各归档。私钥留在本机，明文不进入 Git 或 Nix store。

- 用户应用的 Clash、rclone、JetBrains、botmux 和 CC Switch 配置在 Home Manager 激活时安全初始化。
- NetworkManager 系统连接和 WPS 授权文件由 root 运行时服务恢复到实际使用的位置。
- 输入法学习数据单独恢复。既有文件、符号链接和并发产生的新数据均保留。
- 恢复旧许可证不代表它一定适用于新版本；登录和授权仍由应用官方判断。
- anytls 私钥密文保留；包含私人目标的原隧道单元未部署，不会自动建立连接。

## 验证和使用

```sh
bash tests/eval.sh
nix build --impure --no-link --file tests/xfce-assets.nix
nix eval --impure --json --no-update-lock-file --file scripts/software-inventory.nix
```

检查覆盖来源与会话约束、中文输入、词库与归档安全、flake 和完整系统 derivation；资源检查实际构建并核对主题、光标、图标及壁纸。求值与资源检查不替代完整系统构建和真实硬件登录测试。

只有在目标 NixOS 已安装并备好 age 私钥、确认硬件文件后，才使用 `nixos-rebuild`；入口说明见 [引导](docs/bootstrap.md)。这里不对当前 Manjaro 执行该操作。

继续阅读：[GRUB](docs/boot.md)、[字体](docs/fonts.md)、[软件与 NUR](docs/packages.md)。`inventory/` 中原始 Manjaro 扫描资料作为迁移历史保留，判断当前状态应以模块、最新版本审计和配置覆盖清单为准。

[Nix 存储维护](docs/nix-storage.md)按实际文件系统容量生成空间阈值，保留每周 30 天历史代清理，并定期对 store 去重。

[开发与维护工具](docs/development-tools.md)包含 nh、项目环境与命令索引；
[提交检查与 CI](docs/development-workflow.md)提供统一格式和静态检查。
[用户数据备份](docs/candidates/backups.md)保留为候选方案，尚未启用。

[已实施的桌面精简](docs/desktop-maintenance.md)与
[进一步精简候选](docs/candidates/system-cleanup.md)分别记录当前行为和待确认的替换项。

[Ark](docs/ark.md)为旧中文 ZIP 提供局部编码回退，并明确配置归档后端；
Flatpak、Flathub 注册与 Discover 软件商店已关闭，保留固件更新服务。
