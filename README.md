这是 Orion-Laptop（HP OMEN 16）的 NixOS 复刻配置：用模块化 flake 描述当前 Manjaro 主机的硬件、双显卡、Plasma 桌面布局、中文输入和软件清单。仓库只做求值，不执行 `nixos-rebuild`，也不改正在使用的引导和磁盘。

2026-11-16 检查过：`refs/heads/nixos-26.11` 不存在，`https://channels.nixos.org/nixos-26.11` 返回 404，home-manager 也没有 `release-26.11`。测试线还没发布，系统与 home-manager 跟踪 `nixos-26.05` 和 `release-26.05`。26.05 没有或过旧的属性从输入 `nixpkgs-unstable` 取，不把整台机器切到 unstable。

默认会话见下面「显示」。输入法只保留 fcitx5 一条路径（GTK、Qt、X11、Wayland、Electron）。现场的 `/etc/environment` 里 `XMODIFIERS` 写了两遍，并且 `GLFW_IM_MODULE=ibus` 和 fcitx 冲突；GLFW 那一项已去掉。字体不再叠多份 fontconfig，只留一条 CJK 回退链。Noto CJK 已经在 `modules/chinese.nix` 里。细节在 `inventory/optimizations.md`，对照表在 `inventory/适配清单.md`。

Linux 根文件系统在 btrfs `UUID=fd32207f-8a11-48d7-9d04-9316cdb8c265` 的 `@`、`@home`、`@cache`、`@log` 上，ESP `UUID=0AF1-1155` 与 Windows 共用。没有活动的 swapfile，所以没有写入 `resume` / `resume_offset`。显卡是 Intel 核显显示加 NVIDIA PRIME offload，不是 sync。

## 快捷键

默认是迁过来的 KDE 快捷键，`orion.shortcuts.profile = "current"`，不启用 keyd。仿 macOS 的一套已经可以切换：只在主机文件里写成 `"macos"`。按住 Super 时当作 Command。改回 `"current"` 会关掉 keyd。这不是未办项。

## ranger 和 neovim

home-manager 启用 `programs.ranger` 和 `programs.neovim`，模块在 `home/editors.nix`。配置按原文件放在 `home/ranger/` 和 `home/nvim/`，没有改成 Lua。

迁入的文件：

- ranger：`rc.conf`、`rifle.conf`、`scope.sh`、`commands.py`、`colorschemes/` 的 `__init__.py`、`default.py`、`jungle.py`、`snow.py`、`zenburn.py`、`plugins/__init__.py`、`plugins/devicons.py`、`plugins/devicons_linemode.py`
- neovim：`init.vim`、`addition.vim`、`command.vim`、`coc.vim`、`coc-settings.json`、`dependent.vim`、`keyboard.vim`、`markdown.vim`、`plugins.vim`、`ui.vim`、`autoload/plug.vim`、`Ultisnips/cpp.snippets`

`plugins.vim` 的 vim-plug 声明留着，不拷贝 `~/.config/nvim/plugged`。`coc.vim` 的 `g:coc_global_extensions` 留着，本机没有已下载的 coc 扩展目录。

这些外部命令是因为配置里调用了才加的：

- `w3m`：`rc.conf` 的 `preview_images_method w3m`，`scope.sh` 的 `w3m -dump`
- `atool`：`scope.sh` 和 `rifle.conf` 列压缩包
- `mediainfo`、`ffmpegthumbnailer`：`scope.sh` 的音视频预览
- `poppler-utils`：`pdftotext`、`pdftoppm`
- `djvulibre`：`djvutxt`
- `libarchive`：`bsdtar`
- `imagemagick`：`identify`、`convert`
- `gcc`：`g++`，给 C/C++ 的编译映射
- `clang-tools`：`clangd` 和 `clang-format`
- `efm-langserver`：`coc-settings.json` 里 `languageserver.efm.command`
- `black`：`python -m black`，放在 Neovim 的 Python 3 里

`withNodeJs` 和 `withPython3` 打开，给 coc.nvim 和 Python provider。系统包里已有 `git`、`nodejs`、`python3`、`p7zip`、`unzip`、`ffmpeg`、`universal-ctags`、`bash-language-server`，没有再加一份。`rifle.conf` 里的 `code`、`vlc`、`libreoffice` 也已经在系统包里。

没有加 `ripgrep`、`fd`、`bat`、`highlight`、`ueberzug`、`chafa`，这两份配置没有调用。`rifle.conf` 里的 `perl`、`ruby`、`php` 没有新装解释器。`command.vim` 里的 `BuildComposer` 会跑 `cargo`，但没有任何插件挂上它，没有装 Rust。

跳过、不入库：

- `plugins/ranger_devicons/`：`alexanderjeurissen/ranger_devicons` 的克隆，没有插件声明文件。ranger 实际加载的是同目录的 `devicons.py` 和 `devicons_linemode.py`，这两份已迁入。图标要 Nerd Font，字体不在这两份配置里，没有装。
- `__pycache__`、`.pyc`、`.pyo`
- `rc-sample.conf`、`commands_full.py`：ranger 不加载
- `dependent.vim` 里的 `/usr/bin/python` 和 `/usr/bin/python3`

nixpkgs 的 ranger 会把包内 `rc.conf` 的 `preview_script` 指到自己的 `scope.sh`。迁过来的 `rc.conf` 写成 `set preview_script ~/.config/ranger/scope.sh`，否则这份预览脚本不会被用到。

vim-plug 插件（`plugins.vim`，`:PlugInstall` 时下载）：vimplus-startify、nerdtree、vim-nerdtree-syntax-highlight、vim-airline、vim-airline-themes、vim-commentary、syntastic、vim-easymotion、rainbow、vimcdoc、gundo.vim、ayu-vim、coc.nvim（分支 release）、vim-clang-format、vim-operator-user、vim-autoread、auto-pairs、vim-snippets。

coc 扩展（`coc.vim`，首次启动时下载）：coc-json、coc-vimlsp、coc-tsserver、coc-clangd、coc-sh、coc-pyright、coc-marketplace、coc-html、coc-actions、coc-snippets、coc-markdown-preview-enhanced、coc-webview。

## 显示

默认 X11，因为 ToDesk 远程控制。`services.displayManager.defaultSession = "plasmax11"`（nixos-26.05 上 Plasma 6 的 X11 会话名，来自 `plasma-workspace` 的 `providedSessions`）。Wayland 会话 `plasma` 仍会安装，只在登录界面里选。SDDM 欢迎界面也走 X11：`services.displayManager.sddm.wayland.enable = false`。自动登录用户仍是 `jimmywang0417`。

ToDesk 安装 nixpkgs 的 `todesk`。`orion.nix.allowUnfree` 本来就是开的，没有为它再翻一次开关。不安装 RustDesk。旧的 `/opt/todesk` 开机项是坏的，因为那个包装已经不在；这里不把失效路径装回去。

## 默认应用

doc、docx、rtf、odt 归 WPS 文字（`wps-office-wps.desktop`），xls、xlsx、ods、csv 归 WPS 表格（`wps-office-et.desktop`），ppt、pptx 归 WPS 演示（`wps-office-wpp.desktop`）。PDF 归 Okular（`okularApplication_pdf.desktop`），png、jpeg、gif、webp、svg 归 Gwenview，纯文本和 Markdown 归 Kate。LibreOffice Qt（`pkgs.libreoffice-qt`）有装，用来在本地处理文档，上面这些类型都不是它的默认程序。查询过的类型都有处理程序，没有留空。

现场 `xdg-mime` 里，doc、ppt、odt、ods、rtf 曾落到 LibreOffice，docx、xls、xlsx、pptx 曾落到 ChatGPT。系统级 `xdg.mime.defaultApplications` 把办公文档固定到 WPS，并在 `xdg.mime.removedAssociations` 里去掉对应的 LibreOffice 桌面文件，避免装包顺序再抢走关联。这一步写的是 `/etc/xdg/mimeapps.list`，不改写 `~/.config/mimeapps.list` 里已有的协议关联。

## 校园网与 docker-easyconnect

`orion.easyconnect` 打开的是 docker-easyconnect，不是官方 deb。镜像是 `hagb/docker-easyconnect:7.6.7`，容器名 `easyconnect`。`autoStart = false`，不挂到 default.target。每次 NetworkManager 连接或断开都跑调度脚本。不安装官方 deb，不复制 `/usr/share/sangfor` 里的二进制，也不把 EasyMonitor 写成开机服务。登录凭据不进仓库，探测地址里也不写账号密码。

`campusProbes` 默认是 `[ "https://kq.xjtu.edu.cn" ]`。一条探测要在大约 3 秒的连接超时里完成 HTTPS，HTTP 状态是 2xx 或 3xx，才算打得开这个只在校园网里能访问的网站。只解析出域名不算。认证门户把请求重定向到另一台主机也不算。

容器没在跑，并且探测失败（超时、不是 2xx，或重定向到另一台主机）时才 `docker start`。探测成功而容器停着，说明已经在校园网上，不启动。容器已经在跑时，不因为后来探测成功就 `docker stop`，因为隧道本身可能让这个网站变得可达。只有 NetworkManager 的活动连接是 `XJTU_STU` 或 `xjtuse-lab` 时才停止。`campusSubnets` 仍是空的，不参与判断。名叫「有线连接 1」的以太网不是停止条件。

## 网络和下载

二进制缓存先用中科大，官方缓存作后备。`nixos-26.05` 频道文件 `binary-cache-url` 指向的就是这个中科大地址。

- `https://mirrors.ustc.edu.cn/nix-channels/store`
- `https://cache.nixos.org/`

信任的公钥只有 `cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=`。从中科大取到的 narinfo 签名是这把钥匙。帮助页 <https://mirrors.ustc.edu.cn/help/nix-channels.html> 没有公布第二把，所以没有写入另一把。`nix.settings.fallback = true`：前面的镜像失败时继续试下一个缓存，仍然没有就从源码构建。

Clash Verge 正在监听 mixed 端口 7897，作为 HTTP 代理可用。`orion.nix.proxy` 默认是 `http://127.0.0.1:7897`。nixos-26.05 带的 Nix 2.34 没有 `nix.conf` 的 `http-proxy` / `https-proxy`（2.35 会把这两个键报成 unknown setting），下载走的是 `http_proxy` / `https_proxy`。这个端口因此写进 nix-daemon 的环境，以及 `nix.settings.impure-env`，固定输出构建也能用到。Verge 里单独的 SOCKS 7898 和 HTTP 7899 是关的。这里不写订阅地址。

本机的多线程下载是两套，都不是 Nix 的客户端：

- Motrix 2.4.1（`motrix-bin`）自带 aria2 引擎，`max-connection-per-server` 和 `split` 都是 64。
- Axel 2.17.14 在 `~/.local/bin/axel`，没有 `~/.axelrc`，也没有改连接数的包装脚本，程序默认每个文件 4 条连接。NixOS 安装同版本的 `pkgs.axel`。

Nix 拉 substituter 和源码走自己的 HTTP 客户端。这边的并行数是 `nix.settings.http-connections`，按 Motrix 的 64 放在 `orion.nix.download.httpConnections`。`connect-timeout` 是 10 秒。Motrix 和 Axel 留给手动下载。

`programs.git` 把 `git://github.com/` 换成 `https://github.com/`，git 也走 `orion.nix.proxy`。

这些在 `modules/nix-download.nix`。`hosts/orion` 打开 `orion.nix.download.enable`。改模块之前，现场 `~/.config/nix/nix.conf` 只有实验特性，没有镜像、超时、并行数和代理。

## 未办配置

这些还没有做完。不是已迁移功能的简介。

用户不用，已在本机 paru -R：`grok-bot-bin`、`udf-http-range-proxy`、`keepassxc-unlock`、`verilog-format-git`。

### 已用 sops 加密入库

只写 secret 名。明文不在仓库里。运行时路径是 `/run/secrets/<名字>`，说明在 `secrets/README.md`。

fcitx5-pinyin、clash-verge、anytls-ssh-key、rclone-webdav、jetbrains-licenses、wps-license、botmux-bots。

### 留在本机，不能入库

只记种类，没有秘密内容。

- Win10 字体包 `ttf-ms-win10-auto` 里的字体文件
- CC Switch 数据目录
- v2rayN 的 `guiConfigs`
- NetworkManager 系统连接（`/etc/NetworkManager/system-connections`）未读到，没有加密

### nixpkgs 26.05 没有的包

表达式在本仓库 `pkgs/`，由 `packages.x86_64-linux` 和 `overlays.default` 暴露，并挂在 Orion 的 `nixpkgs.overlays` 上。没有放进 `environment.systemPackages`。构建用 `nix build .#<名字>`。没有第二个包仓库。

- `crm` 0.2.2
- `xjtu-course-genius` 4.6.1
- `xjtutoolbox` 1.4.1
- `botmux` 3.59.15
- `animeko` 6.4.0。nixpkgs 26.05 的 `animeko` 5.3.2 标记为 broken，这份是 AppImage

`alder`、`typora-free-with-plugin` 和 Grok Bot 桌面版没有收进本仓库。

`.github/workflows/ci.yml` 在 push 和 pull request 上构建 `packages.x86_64-linux` 里的每个包，不求值整份 NixOS。nixpkgs 仍钉在 `nixos-26.05`。`.github/workflows/update.yml` 每天 16:00 UTC 跑一次，也可以手动触发；只在 `updates.nix` 里的 GitHub release 版本变化时开 pull request，用默认 `GITHUB_TOKEN`，不会 force-push。

### 等用户开口再写进配置

官方 Typora。破解版 Typora 不在此列，见「不按原样迁的」。

主机 `hosts/orion/default.nix` 里 `orion.nix.allowUnfree = true` 仍然开着，给 NVIDIA 用户态驱动，以及 Chrome、Edge、VS Code、JetBrains、Discord、Steam、Obsidian、ToDesk、WPS 用。

用户要 conda。PyCharm 2025.2 先前唯一的 conda 解释器是 `$USER_HOME$/miniconda3/bin/python`（Python 3.13.2），那个 miniconda3 不存在。Orion 启用 nixpkgs 26.05 的属性 `conda`（`pkgs.conda`，版本 26.1.1-1，pname `conda-shell`，二进制 `conda-shell` 与 `install-conda`，前缀 `~/.conda`）。不安装 Anaconda 发行版。

### 开机项指向已卸载程序，默认不迁移

1Password、RustDesk、Waydroid、`apm-daily-update`。v2rayN 和正在使用的 Clash 重叠，默认不迁移。ToDesk 已改为 nixpkgs 的 `todesk`，见「显示」。

### 配置里已留接口但还没填实的

- sops 的年龄私钥仍只在本机。密文 secret 名见上面「已用 sops 加密入库」。`.sops.yaml` 里只有公钥接收者。
- 快捷键不是未办。`modules/shortcuts.nix` 已提交。默认 `orion.shortcuts.profile = "current"`，此时 `services.keyd.enable` 为 false。改成 `"macos"` 才启用 keyd。toplevel 已求值通过。
- 中科大没有 flake 注册表：`https://mirrors.ustc.edu.cn/nix-channels/flake-registry.json` 返回 404。`nix.settings.flake-registry` 保持上游，没有改成一个不存在的地址。
- nixpkgs 26.05 的 `motrix` 是 1.8.19，本机 AUR 包是 `motrix-bin` 2.4.1。没有用旧版本替换，也没有把 `~/.config/Motrix/system.json` 写进仓库。本机没有单独的 aria2 包或 `~/.aria2`，所以没有新写一份 aria2 配置。
- shell 别名 `pon` 仍指向 `127.0.0.1:10808`，这个端口当前没有进程监听。Nix 用的是 Clash mixed `7897`。别名按现有 `~/.zshrc` 保留。

### NUR

21 个缺口里，NUR 能安装的有 3 个。conda 用这份锁住的 nixos-26.05 属性 `pkgs.conda`（版本 26.1.1-1），不走 NUR，也不装 Anaconda 发行版。其余 17 个仍要自己处理。包都对着这份锁住的 nixos-26.05 看过。

能安装：

- 百度网盘 8.9.7：`nur.repos.freegoxing.baidunetdisk`。和已装版本一致。不要用 `nur.repos.xddxdd.baidunetdisk`，它会把客户端换到仓库自带的 Electron 11.5.0 上。
- 钉钉 9.0.0.261105002：`nur.repos.yakkhini.dingtalk`。和已装版本一致，走调用方的 nixpkgs。这个包捆绑已停止维护的 OpenSSL 1.1，所以 `nixpkgs.config.permittedInsecurePackages` 里只放了 `dingtalk-9.0.0.261105002`。
- WPS 365 12.8.2.21176：`nur.repos.novel2430.wpsoffice-365`。版本号和已装的教育版相同，属性名不带 edu。同仓库的 `wpsoffice` 11.1 和 `wpsoffice-cn` 12.1 都更旧，不用。

社区 NUR 没有：alder、crm、xjtu-course-genius、xjtutoolbox、botmux、animeko、华为云会议、Typora 的更新版本。crm、xjtu-course-genius、xjtutoolbox、botmux、animeko 的表达式在本仓库 `pkgs/`。NUR 里没有深信服客户端。Orion 的校园网服务是 docker-easyconnect，镜像 `hagb/docker-easyconnect:7.6.7`，见「校园网与 docker-easyconnect」。

字体和词库：`nur.repos.rewine.ttf-ms-win10`、`nur.repos.chillcicada.ttf-ms-win10`、`nur.repos.chillcicada.ttf-ms-win10-sc-sup`、`nur.repos.DzmingLi.windows-fonts` 都是再分发字体，不是让用户自己提供文件的封装，所以不接入。CJK 用已经安装的 Noto Sans CJK / Noto Serif CJK，不另装一份 Source Han，也不装 Win10 字体。fcitx5 拼音用户词库是个人文件，NUR 不会有。

秘密不能靠 NUR：Clash 配置、anytls 密钥、rclone webdav、JetBrains 许可证、bots.json、NetworkManager 的 PSK。

上面三项已经写进 flake：输入 `nur` 跟踪 `github:nix-community/NUR/main`，`nur.inputs.nixpkgs.follows` 指向这份 nixos-26.05。包在 `modules/packages.nix`。

## 不按原样迁的

- v2rayN：和正在用的 Clash 重复，代理继续用 Clash。
- ToDesk：`/opt/todesk` 那条开机项是坏的，改装 nixpkgs 的 `todesk`。不用 RustDesk。
- 1Password：密码库继续用 KeePassXC。
- Waydroid：不迁。
- `apm-daily-update`：oneAPI 每日更新，不迁。
- Grok Bot 桌面版：本机已经卸掉，不迁。
- 破解版 Typora：不迁。官方 Typora 也先不装。
- 完整 Anaconda：不迁，只留 nixpkgs 的 `conda`。
- Win10 字体：不接入再分发的字体包。CJK 用已安装的 Noto CJK。
- 深信服安装包：不复制二进制。改用 docker-easyconnect，只在连不上 https://kq.xjtu.edu.cn 时启动；已经在跑时，不因为隧道把这个网站打通就停。
- 华为云会议：不迁。用户不用华为云会议桌面客户端。
- 百度网盘、钉钉、WPS：用 NUR 里和已装版本一致的 `freegoxing.baidunetdisk`、`yakkhini.dingtalk`、`novel2430.wpsoffice-365`，不用 `xddxdd.baidunetdisk`，也不用更旧的 `wpsoffice` / `wpsoffice-cn`。

## 再加一台机器

`modules/hardware.nix` 只由 `hosts/orion/default.nix` 导入，里面是这台机器的 btrfs 子卷和 Windows ESP。`orion.boot`、`orion.chinese`、`orion.nix`、`orion.secrets`、`orion.shortcuts` 仍是开关。桌面、用户、网络、服务和软件包模块目前按 Orion 写死，第二台机器要覆盖这些模块，不要直接改 Orion 的磁盘 UUID。

1. 复制 `hosts/example.nix` 为 `hosts/<名字>/default.nix`。
2. 在 `flake.nix` 的 `nixosConfigurations` 里加一条属性，带上 `system`、`hostName` 和 `modules = [ ./hosts/<名字> ]`。
3. 改主机名、文件系统、initrd 和显卡 PCI，不要复用 Orion 的分区 UUID。

用户 jimmywang0417 的 Plasma 布局在 `home/jimmy.nix`，由主机文件导入。另一台机器可以同样导入，也可以不导入。

| 名称 | 模块文件 | 文档 | 一句话状态 |
| --- | --- | --- | --- |
| 桌面 | modules/desktop.nix | modules/desktop.nix | 默认会话 plasmax11 |
| 秘密 | modules/secrets.nix | secrets/README.md | sops 只写名字 |
| ranger / neovim | home/editors.nix | home/editors.nix | 沿用现有配置 |
| 软件包 | modules/packages.nix | docs/packages.md | deepseek-harness 走 nixpkgs-unstable |
| 本仓库表达式 | pkgs/default.nix | pkgs/default.nix | packages.x86_64-linux 与 overlays.default |
| 引导 | bootstrap/install.sh | docs/bootstrap.md | 已装好且 flake 未开时先跑 |
| GRUB | modules/boot.nix | docs/boot.md | 主题保持现用的；同一系统不在顶层出现两次。 |
