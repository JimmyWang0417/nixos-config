# 配置结构与扩展方式

`flake.nix` 负责输入和主机组合，`hosts/` 负责机器事实，`modules/` 负责 NixOS 功能，`home/` 负责用户配置。各级 `default.nix` 和 `home/jimmy.nix` 显式声明导入，不自动扫描目录。增加文件后需要把它加入对应入口；使用 Git flake 求值时，新文件也必须对 Git 可见。

## 输入与主机

本配置的 NixOS 模块、全局 `pkgs`、Home Manager、NUR 构建依赖和开发 shell 均使用锁定的 `nixpkgs-unstable`。`home-manager.useGlobalPkgs = true` 避免用户配置另外创建一套包集合。stable 的 `nixpkgs` 输入和 NixOS `pkgsStable` 参数保留为显式备用接口，现有功能不使用它安装软件。版本和迁移限制见 [迁移评估](unstable-migration.md)。

运行包集的非自由软件许可由 `orion.nix.allowUnfree` 统一设置，主机明确选择 true；
`modules/packages/policy.nix` 只管理个别兼容与旧依赖例外，不重复打开全局许可。

`hosts/orion/default.nix` 组合 Orion 的主机名、硬件模块、内核选择、功能开关和 Home Manager 用户。挂载、initrd 所需设备及固件声明位于 `hosts/orion/hardware-configuration.nix`。`system.stateVersion` 和 `home.stateVersion` 保持 `26.05`，不随 channel 名称更新。

## NixOS 模块

`modules/default.nix` 只组合七个职责目录：

- `core/`：引导、区域、用户、终端编辑器默认值、Nix 设置与下载、sops 声明和系统私有配置恢复。
- `core/nix-storage/`：历史代清理、自适应空间阈值和定期 store 去重，详见 [存储维护](nix-storage.md)。
- `hardware/`：显卡和 PRIME 等硬件集成。
- `desktop/`：显示会话、音频、蓝牙、MIME、KDE 应用、字体、快捷键和输入法。`input-method.nix` 管 fcitx5 与会话环境，`cjk-fonts.nix` 管 CJK 字体与回退链，`fonts.nix` 管 Windows 字体来源。
- `network/`：NetworkManager 与 EasyConnect 调度。
- `services/`：按打印、设备访问、远程桌面、Flatpak 禁用策略、AppImage、调度、Docker、电源固件和 Clash Verge 等职责拆分。
- `packages/`：软件清单、已有兼容策略以及浏览器和 Steam 的系统集成。
- `programs/`：需要独立行为的应用，例如 DevEco、[Claude Cage](claude-cage.md) 和 [DSH](dsh.md)。

仓库根目录的 `packages/` 保存应用配方，调用方传入同一个全局 `pkgs`。
`packages/dingtalk/` 固定官方负载并复用现有桌面包装；`packages/baidunetdisk/`
把官方负载和必须的 GTKmm2 兼容库分开，兼容库使用当前工具链构建，不另行导入旧 nixpkgs。
`packages/claude-cage/` 分开官方桌面负载与 QEMU/固件/工具运行路径；
`modules/programs/claude-cage.nix` 只管理启用、包选择与可选 KVM 用户组。
`packages/ark/` 保存 Ark 私有依赖补丁与后端包装配方；
`modules/programs/ark.nix` 负责选项、包选择和原生插件策略，详见 [Ark](ark.md)。

`modules/packages/catalog/` 的文件返回包列表；`catalog.nix` 以明确顺序组合这些列表。服务定义、激活脚本和用户状态处理不放进清单。`orion.packages.unstable` 保留原有附加软件接口，所有默认条目仍来自同一个全局 unstable 包集合。兼容入口 `modules/packages.nix`、`modules/dsh.nix` 只导入相应的新目录。

## Home Manager

`home/jimmy.nix` 只保留用户身份、状态版本和功能导入。用户侧按职责拆分：

- `home/modules/apps/<app>.nix`：一个应用的自启动、用户服务或偏好。
- `home/modules/development/`：独立的 elan、rustup 半声明式管理，激活时安装并记录 stable 工具链；
  `node/` 分开管理 Node/npm 环境、shell PATH 和保留现有状态的迁移逻辑。
- `home/modules/editors/`：Neovim、ranger、VS Code；`home/editors.nix` 是组合入口，原始文件保留在 `home/nvim/`、`home/ranger/`、`home/vscode/`。
  Neovim 的 `commands/` 再按格式化、构建、运行及通用进程处理拆分；
  Ranger 将预览依赖放进自身包装器，rc、打开规则、预览脚本各管一项职责。
- `home/modules/shell/zsh.nix`：shell、代理快捷命令和提示符；公开资源位于 `home/assets/shell/`。
- `home/modules/desktop/`：Plasma 布局、主题、[用户目录](user-directories.md)；`xfce/` 再拆为外观、面板、壁纸、快捷键和资源，`home/xfce.nix` 保留组合入口。
- `home/fcitx5/`：公开输入法配置、可写配置部署、私有词典初始化和只读诊断。详见 [输入法](input-method.md)。
- `home/modules/private/`：私有应用配置的运行时恢复入口，与公开偏好分开。

公开应用偏好放在 `home/assets/apps/`。`home/lib/seed-config.nix` 只在目标缺失时初始化可写偏好，并排在私有配置恢复之后；现有文件和符号链接不覆盖。明确由 Nix 管理的 Plasma、输入法等配置按各模块的声明部署。更新提示等强制策略只改对应键，不能把“默认值初始化”和“持续强制设置”混为一种操作。

明文账号、订阅、许可证、聊天状态和 provider 配置不放进这些公开资源。已有敏感归档由 `modules/core/secrets.nix` 声明，通过 `/run/secrets/` 交给运行时恢复逻辑；输入法用户词典只初始化缺失文件，保留后续学习数据。解密要求和各归档用途见 [secrets/README.md](../secrets/README.md)。

## 增加或修改功能

增加一个普通应用时，先把包放进对应的 `modules/packages/catalog/` 文件；需要用户设置时，再建立单独的 `home/modules/apps/<app>.nix` 并加入 `home/jimmy.nix` 的导入。包是否安装、应用如何配置和用户已有状态如何处理分别表达，不用一个大模块同时承担三件事。

可声明的程序优先使用现有 NixOS/Home Manager 选项。需要原始配置文件时，公开且无账号信息的内容才进入 `home/assets/`，并明确选择不可写链接、首次初始化或针对特定键的持续策略。需要 root 服务时，把系统单元放进 `modules/services/` 的对应功能文件；用户单元留在应用的 Home Manager 模块。可复用逻辑单独放在相邻 helper 或 `home/lib/`，调用方传入已有 `pkgs`，不重新 import 一个包集合。

增加 DSH 插件只修改 [DSH 插件分组](dsh.md)，不把插件的下载或用户配置塞进系统软件清单。增加新主机时，在 `hosts/` 新建主机目录并注册 flake 输出，复用功能模块，同时重新确认挂载、内核、PRIME PCI 地址、用户和会话选择；不要直接沿用 Orion 的硬件事实。

## 验证边界

结构调整后运行 `bash tests/eval.sh` 和 `git diff --check`。当前检查覆盖包来源与迁移约束、输入法配置、flake 输出及完整系统 derivation 求值。修改软件清单或搬迁包装函数时，还应对照名称与 derivation，避免重构顺带改变软件；修改插件分组时对照最终名称、数量与顺序。

`flake check` 还实际构建 Ark 归档、Neovim 快捷命令、Ranger 预览、Node/npm
迁移及原生客户端 ELF 依赖检查。测试与所属功能分开，既不下载用户插件，也不
登录客户端或改动真实项目。

求值通过不等于所有软件已构建，也不等于图形会话和设备已在 NixOS 上运行。此仓库仍用于准备 NixOS 配置；验证脚本不会安装、激活、改分区、改引导或重启当前 Manjaro 主机。
