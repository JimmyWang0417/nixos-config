# 百度网盘官方桌面客户端

保留百度官方 Linux 客户端及其登录、上传下载、分享和传输功能，不用网页、
第三方 PCS 或 Flatpak 替代。2026-11-22 核对官方页面实际调用的
[下载接口](https://pan.baidu.com/disk/cmsdata?do=client&adCode=1)，Linux 为
8.9.7，发布时间 2026-10-27。版本与现有 NUR 包相同，本次改善的是依赖来源和封装。

`packages/baidunetdisk/default.nix` 从百度 HTTPS 地址取得原版 `.deb`，使用固定
SHA-256 校验，保留官方文件内容。系统清单仍通过既有 `with-ozone.nix` 为
Plasma Wayland 传递窗口及输入法参数，Xfce X11 不添加这些参数。

旧 NUR 配方为 GTKmm 2 再次导入一个旧 nixpkgs 修订。新配方不再导入另一套
nixpkgs：FHS 环境的库、glibc、libstdc++ 和构建工具都来自传入的全局 unstable
`pkgs`；唯一补充的本地配方是 `gtkmm2.nix`，从 GNOME 上游源码构建 GTKmm
2.24.5，依赖同一包集中的 GTK2、glibmm 2.4、atkmm、cairomm 1.0 和 pangomm 1.4。

这层兼容不能直接删掉：官方 `.deb` 声明依赖 `libgtkmm-2.4-1v5`，其
`libbrowserengine.so` 的 ELF NEEDED 项确实包含 GTKmm、GDKmm 和 GTK2。
换用 GTKmm 3 的文件名不能解决 ABI 差异。它是该闭源应用所需的私有兼容层，
不代表百度已经更新这部分旧引擎；系统已有的 GTK2 弃用提示继续保留。

FHS 环境明确包含 GTK3 的托盘库与当前 fcitx5 GTK 输入模块。启动器继续使用
百度官方 desktop 文件也采用的 `--no-sandbox`，并原样转发参数。FHS 提供文件系统
兼容环境，不据此声称 Chromium 自身的沙箱已启用。

工厂的 `unwrapped`、`compatGtkmm`、`runtimeLibraries`、`officialDownloadApi`
和 `sourcePolicy` passthru 用于审计与只读检查。验证应包含全部官方 ELF 的库解析、
FHS 库目录、托盘与输入模块，以及运行时闭包是否再次引入旧包集合。构建和 ELF
检查不会登录账号、启动 GUI 或读写网盘数据；实际传输、托盘菜单与中文输入仍需
在安装后的 Plasma/Xfce 会话中验证。

本次已构建完整 FHS 包与 GTKmm（含其上游检查），并用固定的 Nix glibc loader
只读解析 18 个客户端运行 ELF、3 个 fcitx GTK 模块和 GTK3 托盘库，均通过。
386 个运行闭包路径中只出现当前 glibc 2.44、GCC 16 运行库，没有旧 nixpkgs
源码树。随官方包保留的 `node_gyp_bins/python3` 是 Python 3.6 构建工具残留，
不作为客户端入口运行，也没有为它引入旧 Python 运行环境。

源码依据：[GTKmm 官方项目](https://gtkmm.org/)、
[GNOME GTKmm 2.24 源码目录](https://download.gnome.org/sources/gtkmm/2.24/)、
[锁定 nixpkgs 中的 GTKmm2 移除记录](https://github.com/NixOS/nixpkgs/blob/2786a2a72088ecf32aea5b3ec52099e6a7cff78f/pkgs/top-level/aliases.nix#L1200)。
