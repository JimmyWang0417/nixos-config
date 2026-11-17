# Typora 与 Windows 10 字体接入

用户已要求在 nixos-config 接入 Typora，并确认字体包名为 `ttf-ms-win10`。

## 来源与接口

- Typora 使用自有 `nur-packages` 的 `packages.x86_64-linux.typora`，不覆盖全局 `pkgs.typora`。仅更新自有 NUR 的固定提交与锁文件，沿用系统 nixpkgs。
- Windows 10 字体使用当前锁定 NUR 的 `pkgs.nur.repos.chillcicada.ttf-ms-win10`。基包已包含微软雅黑、宋体和 Consolas，额外的 `ttf-ms-win10-sc-sup` 不默认安装。
- `orion.fonts.windows.package` 新增为 `nullOr package`，默认 `null`；Orion 主机显式选择上述 NUR 包，模块将其加入 `fonts.packages`。
- 既有 `orion.fonts.windows.enable` 与 `directory` 继续用于额外导入本机目录，保持默认关闭及原有含义。
- 保留现有 Noto CJK 默认回退链，Typora 插件设置沿用 `$HOME/.config/typora_plugin/settings.user.toml`，启动参数通过包的 `override` 接口设置。

## 文档与验证

README、字体和软件包文档、迁移清单应反映实际接入状态，并说明固定来源及两个字体接口。原始 pacman 记录保留原名。

验证 Orion 全部配置可求值、选中了预期版本、无失败断言，并构建字体与 Typora。字体需由 fontconfig 正确识别。保留其他任务的并行改动；发布前同步上游。不激活系统配置。
