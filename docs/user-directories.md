# 英文用户目录与中文桌面

这套机制叫 **XDG user directories（XDG 用户目录）**，不是 `locale-dirs`。
几个文件各有职责：

- `~/.config/user-dirs.dirs` 保存 Desktop、Documents、Downloads 等实际路径映射。
- `~/.config/user-dirs.conf` 控制自动更新，Home Manager 原生生成 `enabled=False`。
- `~/.config/user-dirs.locale` 记录目录命名时的 locale；本机为 `C`，它不决定桌面的
  显示语言。本配置不改写该现有标记。
- Dolphin 的位置与个人书签保存在 `~/.local/share/user-places.xbel`；中文标签可以
  指向英文目录，两者并不冲突。

本机只读核对确认：八个标准目录映射分别是 `Desktop`、`Documents`、`Downloads`、
`Music`、`Pictures`、`Videos`、`Templates` 和 `Public`，Dolphin 中的对应目标也
确实是这些英文目录。原有个人书签保持可写，不把整份 XBEL 纳入 Nix 或重建它。

## NixOS 配置

`home/modules/desktop/user-directories.nix` 显式保留英文映射，仍使用中文
`LANG=zh_CN.UTF-8`，并复用 Home Manager 的只读映射和禁止自动更新策略。
只创建缺失的声明目录，不移动已有内容，也不按中文 locale 改名。

`projects` 继续指向家目录，而不是额外创建 `~/Projects`。旧的
`extraConfig.XDG_PROJECTS_DIR` 在 Home Manager 26.05 的新 schema 中会生成
错误的 `XDG_XDG_PROJECTS_DIR_DIR`；现在改用原生 `xdg.userDirs.projects`。

应用应通过 `xdg-user-dir DOCUMENTS` 等命令或配置文件查询路径；遵循当前
Home Manager 的方式，不额外导出一套可能过时的 XDG 用户目录环境变量。
Dolphin/Qt 按这些映射定位，侧栏仍可以显示“文档”“下载”等中文标签。

`tests/user-directories.nix` 比较完整生成文件的九个映射，并核对禁止自动更新、
中文语言保留、没有额外 Projects 目录以及个人书签不被声明文件覆盖。
本次没有改写本机 XDG/Dolphin 配置或移动本机目录。

依据：[Home Manager 的用户目录模块](https://github.com/nix-community/home-manager/blob/6857c7f7c338ad181729c52071386b0d3afa24bc/modules/misc/xdg/user-dirs.nix)、
[XDG 用户目录项目](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/)。
