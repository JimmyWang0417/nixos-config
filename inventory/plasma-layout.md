# Plasma 布局

扫描时间以这台正在运行的 Manjaro 为准。KDE 配置没有改设计，按文件原样放进 `home/plasma/`，由 `home/jimmy.nix` 的 activation 复制到新登录的 `~/.config`。

plasma-manager 写不出这块布局里真正在用的部件：底部 CPU 饼图（标题「总 CPU 使用情况」、传感器颜色）、长度为 10 且不扩展的 spacer、两块 folder view containment，以及 Aurorae 主题名。所以没有启用 `programs.plasma`，改为部署扫描到的 rc。

## 面板

两块面板，都不浮动，默认厚度 44，`panelOpacity=2`。

底部（containment 2，`location=4`，水平，`panelLengthMode=1` 即 FitContent，`panelVisibility=1`），从左到右：

1. `org.kde.plasma.kickoff`，全局快捷键 Alt+F1。收藏：浏览器、Dolphin、Elisa、Konsole、Pamac、系统设置。
2. `org.kde.plasma.icontasks`。启动器：Konsole、文件管理器、CC Switch、Firefox、Clash Verge、VS Code、Elisa、IDEA、PyCharm、lemon-lime、KeePassXC、系统设置。
3. `org.kde.plasma.panelspacer`，`expanding=false`，`length=10`。
4. `org.kde.plasma.systemmonitor.cpu`，饼图，标题「总 CPU 使用情况」，传感器 `cpu/all/usage`。
5. `org.kde.plasma.analogclock`。
6. `org.kde.plasma.trash`。

顶部（containment 27，`location=3`），从左到右：

1. `org.kde.plasma.appmenu`
2. `org.kde.plasma.panelspacer`
3. `org.kde.plasma.marginsseparator`
4. `org.kde.plasma.showdesktop`
5. `org.kde.plasma.pager`
6. `org.kde.plasma.systemtray`
7. `org.kde.plasma.digitalclock`（`fontWeight=400`）

托盘里启用的插件：mediacontroller、kdeconnect、kscreen、cameraindicator、clipboard、devicenotifier、keyboardindicator、keyboardlayout、manage-inputmethod、notifications、printmanager、volume、weather、battery、bluetooth、brightness、networkmanagement。

## 桌面

活动 id `cbfad0f0-19c0-41cb-a8df-aaca4326b715`，名称「默认」（`kactivitymanagerdrc`）。

- 屏幕 0：`org.kde.plasma.folder`，壁纸插件 `org.kde.image`。
- 屏幕 1：同样是 folder view 和 `org.kde.image`。

两个桌面的 `Image` 指向 nur-packages 的 `whitesur-kde` 壁纸 `share/wallpapers/WhiteSur/contents/images/3840x2160.jpg`。路径在激活时从 Nix store 填入，不提交图片。

`kwinoutputconfig.json` 里的输出：

- eDP-1：2560x1440 @ 165Hz，缩放 1.5，EDID 标识 BOE。
- HDMI-A-1：1920x1080 @ 100Hz，缩放 1，EDID 标识 HWV。
- 名为 X11-0 的输出：3440x1340 @ 60Hz，缩放 1。
- 另有开盖/合盖时的摆放。笔记本全局缩放在 `kdeglobals` 里是 1.5，`kwinrc` 的 Xwayland 缩放也是 1.5。

## 主题

- 图标：`Tela`（`kdeglobals`）。nur-packages 的 `tela-icon-theme`，标准色，目录名 `Tela`。
- 窗口装饰：Aurorae `WhiteSur`（`kwinrc` 的 `__aurorae__svg__WhiteSur`）。nur-packages 的 `whitesur-kde` 提供这个目录名。
- 任务栏：`code.desktop`、`idea.desktop`、`pycharm.desktop`、`clash-verge.desktop`。`CC Switch.desktop`、`lemon-lime.desktop`、`org.manjaro.pamac.manager.desktop` 在 nixos-26.05 和现有 NUR 里没有对应包，id 保留。
- 外观包名：`org.manjaro.breath-light.desktop`。配色写在 `kdeglobals` 正文里，不依赖那个 Manjaro 包也能保住当前颜色。
- `plasmarc` 的 Theme name 是 `default`。
- SDDM：`kde_settings.conf` 在 `00_manjaro_settings.conf` 之后把主题写成 breeze，光标 `breeze_cursors`。配置里采用 breeze。
- 锁屏超时 30 秒。
- 虚拟桌面 2 个、2 行。平铺默认三列 0.25 / 0.5 / 0.25。
- `kwinrulesrc` 是空规则，没有窗口规则可迁移。
- 没有 `ksplashrc`，没有 Latte 配置。

`~/.local/share/plasma/plasmoids` 里的 panon、latte separator、window title、org.communia.apptitle 没有出现在 appletsrc 里，不放进布局。

Kickoff 的 Alt+F1 写在 appletsrc 里。`kglobalshortcutsrc` 有 17KB 的个人快捷键，没有整份复制。
