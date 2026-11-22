# 钉钉官方 Linux 客户端

`packages/dingtalk/default.nix` 使用官方 amd64 DEB `9.0.0.261118001`，在已锁定的
NUR yakkhini 配方上只替换官方负载。当前 nixpkgs-unstable 没有 `pkgs.dingtalk`
桌面客户端；`dingtalk-workspace-cli` 也不能替代聊天、会议等桌面功能。

## 来源与版本

2026-11-22 核对[官方下载页面](https://www.dingtalk.com/download)及其 Linux
amd64 选择器 `https://www.dingtalk.com/win/d/qd=linux_amd64`，服务器返回的目标是
[该官方 DEB](https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_9.0.0.261118001_amd64.deb)。
包内版本文件为 `9.0.0-Release.261118001`，文件大小 396052172 字节，SHA-256：

```text
83406e08854f0bf99fa1754d6b6825a9cb53ca5afc6ea1c500341c88cea14769
```

这比旧配方的 `9.0.0.261105002` 更新；官方页面仍把 Linux 版称为测试预览，
这里不把它描述成官方承诺的稳定版本。包由 Nix 固定 URL 与摘要，不运行应用内更新器。

## 桌面兼容

继续复用 NUR 原有的桌面入口、Qt 包装、Fcitx 检测与输入法环境。主程序使用
`QT_QPA_PLATFORM=xcb`，在 Plasma Wayland 中走 XWayland；不强行改成原生 Wayland。
会议屏幕共享继续加载同一 unstable 包集构建的
[Wayland 共享桥接](https://github.com/lzl200110/dingtalk-wayland-screenshare)，
通过 libportal 和 PipeWire 请求画面。该桥接上游只报告了 Hyprland 测试结果，
所以构建通过不能替代本机 Plasma 下的会议验证。

本次不更换官方客户端、不改托盘实现、不登录账号或迁移聊天数据。中文输入、托盘、
通知、音视频与屏幕选择器仍需在部署后的真实会话中逐项确认。

## 仍然存在的 OpenSSL 问题

直接检查新官方 DEB，`libssl.so.1.1` 与 `libcrypto.so.1.1` 内仍有
`OpenSSL 1.1.1g 21 Apr 2020` 版本字符串。旧版也携带这两份库；问题来自官方
二进制负载，不是 FHS 环境额外引入的旧 Nix OpenSSL 包。

因此保留 `knownVulnerabilities`，并把 `permittedInsecurePackages` 限定为当前
准确包名 `dingtalk-9.0.0.261118001`。不把 OpenSSL 3 伪装成 1.1，也不静默删除
警告。升级客户端没有修复这两份旧库；容器或进程隔离同样不能修复其代码漏洞。
只有厂商更新库或有可验证的同 ABI 安全修复，才能重新判断是否撤销该例外。

基础配方出处：[锁定的 NUR 定义](https://github.com/Yakkhini/nur-packages/blob/c656b0323738cbcb59be1915bbe65a4f984d7376/pkgs/dingtalk/default.nix)。

## 本次验证

新客户端与共享桥接已实际构建通过。静态检查确认二进制包装仍设置 xcb、清除
`WAYLAND_DISPLAY` 并加载共享桥接；内部启动脚本保留 Fcitx 检测且通过 shell
语法检查。主库 `dingtalk_dll.so` 与 `doctor` 仍显式需要 OpenSSL 1.1 的 SONAME，
所以不能通过删除元数据警告来宣称问题已解决。`doctor` 没有 GTK/GDK 未解析符号，
继续移除其无实际用途的 GTK2 依赖。验证未启动厂商程序或访问账号数据。
