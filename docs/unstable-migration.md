# 2026-11-22 软件来源迁移评估

## 决定与实施范围

原配置是锁定的 NixOS 26.05 包集，加少量 unstable 和 NUR 应用。核对发现
VS Code、KDE Gear、Plasma、Pandoc、Typst、Clash Verge 等常用软件存在明显版本
差距，值得调整软件来源。该结论针对仓库实际锁定版本，不能据此声称所有 stable
channel 软件都停止维护，也不能把安全补丁/LTS 分支简单等同于旧软件。

用户最终明确：stable 只保留源和使用接口，所有软件使用 unstable。因此当前策略为：

- `nixpkgs`：保留 `nixos-26.05` 输入，只提供显式 `pkgsStable` 参数。
- `nixpkgs-unstable`：统一使用 `nixos-unstable`，锁在
  `2786a2a72088ecf32aea5b3ec52099e6a7cff78f`（2026-11-21）。它提供 NixOS
  模块和全局 `pkgs`，系统、服务、桌面、驱动、字体、Home Manager 和开发环境均使用它。
- Home Manager：`master`，锁在 `6857c7f7c338ad181729c52071386b0d3afa24bc`。
  Home Manager、硬件、sops、NUR、自有包的 nixpkgs 输入均 follows unstable。
- Lean/Rust 工具链按后续用户要求改为半声明式：管理器仍来自 unstable，编译器由
  elan/rustup 在激活时下载 stable 并写入可写配置，具体版本不由 flake.lock 固定。
- 自定义 NUR 软件保留其配方和功能，构建依赖改为 unstable；其客户端版本仍由
  对应 NUR 仓库维护。切换 nixpkgs 不会自动更新自定义配方。
- `system.stateVersion` 与 `home.stateVersion` 保持 `26.05`。Plasma 改为默认 Wayland，另启用 Xfce X11 供 ToDesk 使用。
  SDDM 欢迎界面继续使用 X11，保留 PRIME offload 与 Linux 6.12 LTS 系列。

截至核对日，官方 [26.11 分支查询](https://api.github.com/repos/NixOS/nixpkgs/branches/nixos-26.11)、
[26.11 channel](https://channels.nixos.org/nixos-26.11/git-revision) 和
[Home Manager release-26.11](https://api.github.com/repos/nix-community/home-manager/branches/release-26.11)
均返回 404；[开发版发布说明](https://nixos.org/manual/nixos/unstable/release-notes.html)
仍标记 26.11pre。因此当前是 26.11pre 配置，不能称为正式 26.11。

## 全量核对的口径

审计对象是求值得到的系统与 Home Manager 包、字体、VS Code 扩展、内核、驱动、
固件及显式声明的 Python/输入法/包装应用等组件，也包含声明的 DSH、coc 和 Vim 插件。
同一个包重复安装不重复计数。KDE 的多个组件可能共用同一发行版本，组件数量不等于
互相独立的桌面应用数量。没有把整个传递依赖闭包当成用户软件数量。

基线是提交 `1360efe3a36405163c3438314a930fe90f076aa7`。逐项报告保留
官方发布地址、检查方法和无法确认的原因：

- [系统软件逐项结果](../inventory/software-versions-system.json)
- [Home Manager、桌面、字体、扩展和插件结果](../inventory/software-versions-home.json)
- [锁定修订与发布状态证据](../inventory/software-audit-context.json)

GitHub latest 是维护者指定的稳定发布标签；GNU/厂商发布目录、PyPI、npm latest 和
Marketplace stable 使用各自的发布规则。上游 latest 有时仍包含预发布标识或落后于
另一个活跃系列，报告会标记这种差异。未知版本绝不计为“已是最新”。生成的配置文件、
包装器通常没有独立的官方版本；运行时管理的插件也不能从 flake 推断实际已安装版本。

选择 unstable 不保证每个程序都与官方最新稳定版一致；渠道需要打包和测试时间。
Linux 6.12、JDK 等 LTS 分支需要同时比较所选分支的最新补丁与上游最新大版本。
Typora 免费版与插件组合、部分 NUR 软件等保留了原有选择，需要单独看待。
p7zip 仅保留历史记录，当前系统与 Ranger 已统一使用官方 `7zz`；两个项目不做数字跨比较。

## 核对结果

当前完整导出快照为 666 个 Nix 配置包条目，按实际包名称去重为 532 个软件/组件名称。
合并报告共 612 条历史与当前核对记录，包含原有 69 个运行时插件/管理器声明和
2 个 stable 工具链声明。当前仍声明 68 个运行时插件/管理器；Syntastic、cron、旧JACK包装、
Flatpak、Discover、FlatpakKCM、X11字体聚合包与p7zip保留历史记录，但不计入当前状态统计。
该快照的全部包名称均有覆盖；这不等于每个项目的官方版本都能独立确认，也不等于已激活NixOS。

原配置中有 258 条已核实落后官方稳定发布；当前配置仍有
92 条存在版本差距，252 条有可比较的迁移前后版本变化。
当前 27 条未能确认上游版本、24 条只有源码标签依据，均未算作“已是官方最新”。
KDE子组件、私有依赖和生成包装不等于互相独立的桌面应用，LTS、ABI兼容系列与预览版另行分类。

Ark 的 9 个显式后端/私有库声明保持独立作用域；Ranger 显式跟踪 19 个辅助依赖，
通过自身包装器的 PATH 提供。新列出的ExifTool13.60和Highlight4.21
分别落后官方13.64与v4.22；file5.48与coreutils9.12一致，odt2txt只有v0.5标签依据。
7zz26.04仍落后官方26.06。原有Ark私有libzip的中文ZIP回退策略和上游差距记录保留，
没有因为Ranger或全局7zz选择变化而替换其他应用的libzip。

[钉钉](dingtalk.md)更新到官方当前Linux负载9.0.0.261118001；官网仍称该Linux版为测试预览，
因此不把它计作厂商承诺的stable。随附OpenSSL1.1旧库问题仍在，准确包名的安全例外没有静默删除。
[百度网盘](baidunetdisk.md)仍为官方8.9.7；改善是移除旧NUR内部旧nixpkgs导入，改为同一全局
工具链构建的本地FHS封装和GTKmm2.24.5私有兼容层。该库只在实际所需2.4ABI系列内比较，
不拿GTKmm4当可直接升级的替代。

新声明的[Claude Cage](claude-cage.md)是Lee-xeo的VM桌面v0.1.8，官方API标记非预发布；
不是同名Wayland compositor。其OVMF202608、libnotify0.8.9和zenity4.2.2与各自核实的发布系列一致；QEMU11.1.2
仍落后官网当前稳定11.1.3，11.2rc1被明确排除。随包Mihomo1.19.33只作为内嵌组件记录，
不伪造独立Nix包。主机包/运行时检查不等于已下载客机、已配置代理或已完成Claude授权。
最终整合构建检查与配置求值已通过；客机和真实桌面行为仍需部署后确认。
仓库内保留上一发布提交的 CI 证据，本次上传结果随对应提交报告确认。

elan 和 rustup 管理器仍来自 unstable。用户明确选择通过管理器在用户目录初始化
并持久设置 stable 工具链；这两个运行时工具链没有伪造已安装版本，也不计为
已验证最新或落后。原来本次迁移中间加入的固定 Rust 编译器包已移除，避免与 rustup
代理冲突。策略和激活步骤见 [工具链说明](toolchains.md)。

比较前核对真实项目身份，避免把别名当成不同项目：SOPS 安装器不与 SOPS CLI
比较，GRUB 使用实际 EFI 配方，编译器/Qt 包名称与选择属性分别保存。

明显改善的例子：VS Code `1.119.0 → 1.147.0`，Plasma `6.6.6 → 6.8.3`，
KDE Gear `26.04.3 → 26.08.3`，Neovim `0.12.4 → 0.12.6`，Typst
`0.14.2 → 0.15.1`，LibreOffice `25.8.5.2 → 26.8.3.1`。

仍有差距的例子：Pandoc `3.7.0.2` 对比上游 `3.14`，Clash Verge `2.5.2`
对比上游 `2.5.10`，SOF 固件 `2025.12.2` 对比上游 `2026.09.2`。新加入的
开发工具也可能落后上游；选择 unstable 不是每个包已更新到最新的保证。自定义 NUR
客户端和有意选择的 Typora 免费版组合不会因 nixpkgs 分支变化自动更新。

[合并数据](../inventory/software-versions.json)保留全部版本与分类，
[配置覆盖清单](../inventory/configuration-coverage.json)另外说明各应用配置如何管理，
[验证记录](../inventory/software-audit-context.json)记录来源、会话、输入法、安全归档、
主题资源和系统 derivation 的检查结果。

## 复核和以后更新

导出当前配置清单：

```sh
nix eval --impure --json --no-update-lock-file --file scripts/software-inventory.nix > /tmp/software-inventory.json
bash tests/eval.sh
```

`tests/package-source.nix` 检查实际包集路径、输入依赖、编辑器、浏览器、桌面、驱动、
内核及已声明包的 stable 来源泄漏，并检查 stateVersion、X11 和 PRIME 约束。
Plasma 6.8 的 [官方公告](https://kde.org/announcements/plasma/6/6.8.0/)明确退役了
Plasma X11 会话，因此原 `plasmax11` 已无法求值。用户确认改用默认 Plasma Wayland
并提供 Xfce X11 备用会话。Xfce 同样使用 unstable，外观按原 WhiteSur/Tela 配置适配。

百度网盘 FHS 环境及 GTK2 输入法模块仍依赖 GTK2。新 nixpkgs 将其标为将在 27.05
移除；这里只为 `gtk+` 的 broken 问题设置 `warn`，没有全局允许 broken 软件。
该警告保留可见，后续应迁掉 GTK2 依赖。

版本审计脚本只读官方元数据，入口与参数见 `scripts/audit-package-versions.py --help`；
Home/插件检查脚本见 `scripts/audit-home-versions.py`。它们不安装或更新插件。

以后更新实际软件：

```sh
nix flake update nixpkgs-unstable home-manager
bash tests/eval.sh
```

自定义客户端有新配方时，另更新对应 NUR 输入并重新验证。

待官方 `nixos-26.11` 确实可用，再把保留的 `nixpkgs.url` 改成
`github:NixOS/nixpkgs/nixos-26.11`，执行 `nix flake update nixpkgs` 和验证。
按照最终策略，运行包集继续使用 unstable，Home Manager 仍保持与之匹配的 master。

本次工作只修改和求值仓库配置。当前运行系统仍是 Manjaro；没有执行 NixOS 安装、
激活、磁盘或引导变更。求值通过只证明配置与 derivation 可生成，不代表整套系统
已构建完成，也不替代显卡、休眠、输入法、远程控制等实际硬件测试。
