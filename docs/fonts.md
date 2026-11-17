# 字体

## 安装的字体与回退

默认的 CJK 回退仍是 Noto Sans CJK 和 Noto Serif CJK，也就是 Source Han 的 Noto 发行。`fonts.fontconfig.defaultFonts` 的回退链不改。Carlito、Caladea 用 nixpkgs 里的开源包，度量分别对应 Calibri 和 Cambria。

Orion 另外安装 `pkgs.nur.repos.chillcicada.ttf-ms-win10`。基包包含 144 个 TTF/TTC 文件，约 320.8 MiB，包括微软雅黑、宋体和 Consolas，供应用或文档按字体名选择。不安装 `ttf-ms-win10-sc-sup`，不把 Microsoft YaHei 插到 Noto CJK 前面。

## 包选择接口

`orion.fonts.windows.package` 的类型是 `nullOr package`，模块默认 `null`。非空时，`modules/fonts.nix` 自动把所选包加入 `fonts.packages`。Orion 在 `hosts/orion/default.nix` 显式选择：

```nix
orion.fonts.windows.package = pkgs.nur.repos.chillcicada.ttf-ms-win10;
```

这个包来自 `flake.lock` 锁定的社区 NUR 输入：NUR 修订为 `3c58790b9868a47aeaef4d9a6667f5927924140a`，其中 `chillcicada/nurpkgs` 的打包表达式固定在 `4534a63f4e787658ff062dfc415f732fd0b54a47`。字体数据来自 [streetsamurai00mi/ttf-ms-win10](https://github.com/streetsamurai00mi/ttf-ms-win10)，该表达式固定的数据修订为 `417eb232e8d037964971ae2690560a7b12e5f0d4`，哈希是 `sha256-UwkHlrSRaXhfoMlimyXFETV9yq1SbvUXykrhigf+wP8=`。不依赖 AUR 网页，也不从正在使用的 Windows 分区读取。字体文件不提交进本仓库；构建产物在 Nix store，NixOS 通过 `fonts.packages` 注册它们。Orion 已启用 `allowUnfree`。

取消包式安装时把主机的 `package` 改为 `null`；换包时传入其他字体 derivation。包选择不依赖下面的本机目录开关，正常纯 flake 求值不需要 `--impure`。

## 本机目录额外导入

原有的 `orion.fonts.windows.enable` 和 `directory` 继续保留，只控制从本机目录额外复制字体。`enable` 默认 false，Orion 也保持关闭；`directory` 默认是 `users.users.jimmywang0417.home` 下面的 `.local/share/fonts/windows`。

需要这条路径时，把自己的字体放进目录再打开开关：

```nix
orion.fonts.windows = {
  enable = true;
  directory = "/absolute/path/to/extra-fonts";
};
```

此接口只复制目录顶层的 `*.ttf` 和 `*.otf`，不递归，也不导入 TTC。包式安装的 Win10 基包包含 TTC，不受这个本机目录筛选限制。打开目录导入后，求值要加 `--impure`，否则 flake 看不到外部目录；目录不可见或不存在时会触发断言，目录存在但没有支持的字体时只告警。关闭时，不存在或空目录不会影响求值。

## 检查

系统应用配置后可用 `fc-list` 查询安装的字体，用 `fc-match 'Microsoft YaHei'`、`fc-match SimSun`、`fc-match Consolas` 检查按名匹配。`fc-match sans-serif:lang=zh-cn` 应继续按已有 Noto CJK 回退链选择字体。这里安装字体不等于修改应用自身的字体设置。

## 相关文件

- `modules/fonts.nix`：可选包与本机目录导入接口
- `hosts/orion/default.nix`：Orion 显式选择的 Win10 字体包
- `modules/chinese.nix`：Noto CJK、Carlito、Caladea 与 fontconfig 回退
- `flake.nix`、`flake.lock`：NUR 输入与版本锁定
- `.gitignore`：本机字体文件不入库
