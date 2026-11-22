# 候选：进一步精简与替换

本轮已按用户确认关闭 Baloo、空 cron 和 JACK 的全局库路径注入，Neovim 保留
Coc 并清理 Syntastic 与重复 clangd 注册。Flatpak 已按用户后续确认关闭，
其余候选的启用条件和功能影响仍需分别核对。

1. **Flatpak 与 Flathub 注册（已实施）**：已明确关闭 Flatpak，移除开机注册
   Flathub 的单次任务和其远程描述文件下载。保留独立策略模块，日后需要时再开启。
   不删除现有用户数据，也不影响 AppImage 与 Nix 提供的软件。
2. **全局科研 Python/Conda 环境**：已配置 direnv/nix-direnv，适合把 FastAPI、
   NumPy/科学计算相关依赖和项目特定 Node/JDK 逐步放进项目 devShell。
   保留基础命令、Neovim provider 和 Rust 链接器，不把 pipx 的 CLI 用途混同于
   项目依赖。需要已有项目逐一提供环境后再撤销全局依赖。
3. **旧 p7zip（已替换）**：系统使用官方 Linux 7-Zip 的 `_7zz`。
   ranger 的预览、列表和通过 atool 解包均使用 `7zz`。[官方发布](https://www.7-zip.org/download.html)
4. **钉钉的旧依赖例外**：目前的 NUR 配方需要显式允许旧 OpenSSL 依赖；
   OpenSSL 1.1.1 已结束上游公开支持。应优先找能取消该例外、仍满足钉钉功能的
   包配方。换成 Flatpak 并不能自动证明捆绑库已更新。
   [上游支持状态](https://openssl-corporation.org/blog/2023-09-11-eol-111.html)
5. **ModemManager / bolt**：前者管理蜂窝调制解调器，后者管理 Thunderbolt
   外设授权。只有确认不需要相应设备时才停用；当前没有足够证据认定硬件不存在。
   [ModemManager](https://modemmanager.org/)
6. **登录自启**：CC Switch GUI 与 botmux 桥接可以按实际使用频率决定改为手动。
   不推定每次登录都不需要它们，也不连带关闭用户已依赖的代理和设备管理。
7. **Neovim 插件生命周期**：以后可把可打包插件转入原生 Nix 插件管理，并把
   其余同步操作独立成显式命令。需要保留现有插件功能和 Coc 扩展，不能直接
   删除现有插件引导。用户指定的 elan/rustup stable 下载行为继续保留。

Docker 是当前 EasyConnect 方案的依赖；Plasma、Xfce X11 和 ToDesk 是用户明确
需要的组合，不列为无用软件。thermald 和 power-profiles-daemon 的职责不同。
CUPS 已按需启动，SANE 启用也不等于开启了 saned 网络守护进程。

多个编辑器、浏览器和办公软件可能有不同用途，按使用习惯再精简。
相同 derivation 在系统与 Home Manager 中重复声明会由 Nix 共享存储，
不能把删掉一处声明算成节省了一整份软件空间。
