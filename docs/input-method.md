# 中文输入法

两种桌面都使用 fcitx5 和中文拼音，输入法配置在
`home/fcitx5/`，系统接入在 `modules/desktop/input-method.nix`。
`profile` 保留中文键盘与拼音，默认输入法为 `pinyin`；`pinyin.conf`
保留云拼音设置。配置文件在 Home Manager 激活时部署为可写副本，设置工具
`fcitx5-config-qt` 可以正常保存修改；下一次激活重新应用仓库中的声明。
默认切换键为 `Ctrl+Space`，也可以在设置工具里调整。

## Plasma Wayland

KWin 按 `kwinrc` 的 `InputMethod` 启动这一代 Nix store 中的 fcitx5，
从而提供原生 Wayland 输入法套接字。普通自动启动入口在 Wayland 下立即退出，
避免另起一个拿不到 KWin 套接字的实例。修改系统配置后重新登录生效；
不要用托盘里的“重新启动”代替重新登录 KWin 会话。

`XMODIFIERS=@im=fcitx` 继续提供 XWayland/XIM 兼容。
`GTK_IM_MODULE`、`QT_IM_MODULE` 和 `SDL_IM_MODULE` 不写进全局登录环境；
会话脚本也清理继承来的旧值。GTK 3/4 和现代 Qt 使用合成器的原生文本输入。
Qt 6 的模块回退次序是 `wayland;fcitx;ibus`，同时导出当前 fcitx 包中
Qt 5、Qt 6 的插件目录。

这遵循 [Fcitx 的 Wayland 配置说明](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)。
它也说明了旧版或自带 Qt 的专有软件可能需要逐个应用指定输入模块。
遇到某个强制 XWayland 的旧程序无法输入时，可分别尝试
`env GTK_IM_MODULE=fcitx 程序` 或 `env QT_IM_MODULE=fcitx 程序`；
不要把这些试验值写回整个 Wayland 会话。

## Xfce X11

显示管理器在启动 Xfce 之前设置 `GTK_IM_MODULE=fcitx`、
`QT_IM_MODULE=fcitx` 和 `SDL_IM_MODULE=fcitx`。
fcitx 的自动启动文件包含 `XFCE`，会话不依赖 Plasma 的启动脚本。
该分支同时清理 Electron 的 Wayland 提示。

GTK 2 输入模块显式启用，GTK 2/3 的模块缓存由 NixOS 生成；
GTK 4 的模块通过 profile 的 `GTK_PATH` 暴露。GTK 2 仍依赖仓库中
针对 `gtk+` 的弃用兼容许可，需在升级至移除 GTK 2 的版本前处理。

## VS Code

VS Code 使用当前锁定 unstable 提供的包装器。仅当
`NIXOS_OZONE_WL` 和 `WAYLAND_DISPLAY` 都存在时，包装器才加入
`--enable-wayland-ime=true`、`--wayland-text-input-version=3` 等原生 Wayland
参数。Xfce X11 不会被强制切到 Wayland。这里不再添加第二层重复包装器。
中文界面、语言扩展和用户启动参数由编辑器模块维护，见
[VS Code 配置](vscode.md)。

## 个人词库

`fcitx5-pinyin` 是由 sops 解密到 `/run/secrets/fcitx5-pinyin` 的归档，
其中仅导入已核对的 `user.dict`、`user.history`，目标为
`$XDG_DATA_HOME/fcitx5/pinyin/`。
只有缺失的目标文件才会初始化，文件权限为 `0600`；已有学习记录、
已有符号链接和激活后新增的词条均不覆盖。导入程序不使用归档路径解压，
也不把明文放进 Nix store。缺少已解密 secret 时保留现有数据，之后可在
secret 可用时重新运行 Home Manager 激活。

## 验证和诊断

仓库检查：

```sh
python3 tests/input-method.py
bash tests/eval.sh
```

检查包含实际包集中的 GTK 2/3/4、Qt 5/6 模块和插件搜索路径、VS Code 的
条件包装参数，以及真实生成会话脚本的 X11/Wayland 分支。词库导入另用临时
合成归档验证重复激活、已有学习记录、权限和恶意链接边界。

安装并登录目标 NixOS 后，在需要输入中文的桌面里运行：

```sh
bash home/fcitx5/diagnose.sh
fcitx5-diagnose
```

先在 Kate 和 VS Code 输入中文，再分别在 Firefox、终端和所用专有应用里
核对候选窗、标点与切换键。配置求值和脚本测试不能替代目标桌面的实际打字、
候选窗位置和远程会话测试；当前 Manjaro 会话不代表已迁移系统的运行结果。
