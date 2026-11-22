# Claude Cage 的 Claude 环境

这里配置的是 [Lee-xeo/Claude-Cage](https://github.com/Lee-xeo/Claude-Cage)，不是同名 Wayland compositor，也不是其他 Claude Bubblewrap 封装。固定 [v0.1.8 稳定版](https://github.com/Lee-xeo/Claude-Cage/releases/tag/v0.1.8)，不采用 0.2.0 的预发布版。官方 Linux deb 的 SHA-256 为 `7eb68b00dd94c26c3b2b3408c33d1e047eafa08a10bb6ca8c85118896345e018`。

上游公开支持的 Linux 主机是 Debian/Ubuntu；本仓库提供 NixOS 路径和依赖适配，不能把主机包自检称作上游已验证 NixOS 客机全流程。

## 已经声明的主机环境

`modules/programs/claude-cage.nix` 提供 `orion.programs.claudeCage.enable`、`package` 和 `users`。Orion 已有 `kvm-intel` 与用户的 `kvm` 组，直接复用；其他主机可用 `users` 给已有账户补 KVM 组，并自行按 CPU 配置内核模块。没有启用 libvirt、特权服务、宿主 TUN 或额外防火墙规则。

`packages/claude-cage/default.nix` 包装官方 GTK 3 / WebKitGTK 4.1 桌面、静态后台与随附的 Mihomo **1.19.33**。主程序 MIT、独立 Mihomo GPL-3.0，完整官方许可材料随包保留。GTK、WebKit、QEMU、OVMF、OpenSSH、Git、iproute2、systemd 与 Fcitx GTK 模块全部来自全局锁定的 unstable 包集。QEMU 和 OVMF 在私有工具目录中按上游 Lima 的固件发现方式连接，不创建 `/usr` 文件或下载固件。

安装后从菜单打开 **Cage**，命令为 `cage-desktop`；后台命令是 `claude-cage`。`claude` 仍是主机的 Claude Code，进入 Cage 后才运行客机里的 Claude。包保留 WebKit 沙箱，不设置关闭沙箱的环境变量。Fcitx 模块可见，Wayland/X11 选择继续遵循现有桌面输入法策略，不强制 `GTK_IM_MODULE` 或切回 X11。界面自检不能代替真机上的中文预编辑和候选窗验收。

## 首次启动仍需本人完成

以下步骤按固定版本的[官方首次使用指南](https://github.com/Lee-xeo/Claude-Cage/blob/v0.1.8/docs/getting-started.md)执行，不会在 Nix 构建、登录桌面或系统激活时自动运行。

1. 以普通用户打开 Cage，创建本地账户并保存恢复密钥。确认 KVM 可用：`test -r /dev/kvm && test -w /dev/kvm`。没有访问权限时重新登录桌面让组成员资格生效，并检查 BIOS 虚拟化。
2. 在「网络与代理」导入自己的 Clash/Mihomo YAML 或手动 HTTP/SOCKS5 节点，明确选择出口并「应用代理」。订阅地址、密码和节点配置只在应用运行时输入。需要通过主机网络首次下载订阅时，由本人勾选对应选项；仓库不替用户选择节点，也不读取 Clash 私有配置。
3. 为本机环境选择 **Debian 13** 和存储位置，再启动环境。不要选择「自动匹配本机系统」来期待 NixOS 客机支持；官方稳定版没有声明该组合。默认虚拟盘上限 24 GiB。首次启动由官方流程下载系统镜像、Node.js 24、mise、code-server、浏览器与官方 Claude Code，随后保存在虚拟盘里；这些可变客机工具由 Cage 管理，不使用宿主的 npm 前缀或缓存。
4. 在网络检查通过后，确认 Cage 的出口、时区、语言与浏览器环境设置，使用其出口检测/自动匹配入口完成联动。新建客机终端运行 `claude`，在 **Cage 浏览器**中完成本人 Claude 授权；需要 Claude Desktop 时再从工作台选择安装。安装主机包不等于已下载客机、已配置代理或已登录 Claude。
5. 通过「打开项目」只共享要处理的目录。先用一个无秘密的测试仓库验证读写、Git 提交和中文输入，再打开真实项目。任务结束时在应用内停止环境；单纯关闭窗口可能保留后台任务。

## 状态与权限边界

沿用上游默认的可写 `~/.claude-cage`，可由运行时 `CLAUDE_CAGE_CONFIG` 指向独立配置文件；仓库不生成含代理、密码或会话的 JSON，不覆盖现有配置。该目录与用户选择的存储位置保存应用设置、认证和虚拟磁盘；卸载主机包不会替用户删除它们。备份前停止环境并将其作为私密资料保存。详细保留行为见[官方 Linux 文档](https://github.com/Lee-xeo/Claude-Cage/blob/v0.1.8/docs/linux.md)。

宿主的 `~/.claude`、Claude 认证、`~/.ssh`、SSH agent、npmrc 和 Node/npm 的 XDG 数据目录不会自动共享到客机。宿主 `NPM_CONFIG_*` 指向主机路径，不能作为 Debian 客机的配置；客机有独立 Node、HOME 与账户。远程主机功能中的 SSH 凭据由用户在 Cage 内按需添加，并核对主机指纹。本地客机所需的 Lima 内部 SSH 由 Cage 管理，不要求导入个人密钥。

共享目录内的修改、删除和 Git 操作作用于原始文件；同一配置下的项目也不获得各自独立的客机。不要把整个 HOME 或含密钥目录作为项目共享。网络诊断只能提供当前配置与采样证据，不能保证账号不受限制。

## 验证范围

包的 `tests.runtime` 验证后台版本、内嵌 Web 资源、桌面 origin 策略自检、Mihomo 版本、QEMU/镜像工具、OVMF 文件，以及桌面 ELF 实际加载当前 glibc/GTK/WebKit。全部使用只读命令，不创建用户配置、不启动 VM、不下载客机、不登录服务。实际 KVM 启动、代理出口和 Claude 授权必须在目标 NixOS 桌面按上述步骤完成。
