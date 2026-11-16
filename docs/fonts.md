# 字体

## 作用

默认装上的 CJK 仍是 Noto Sans CJK 和 Noto Serif CJK，也就是 Source Han 的 Noto 发行。`fonts.fontconfig.defaultFonts` 的回退链不改。Carlito、Caladea 用 nixpkgs 里的开源包，度量分别对应 Calibri 和 Cambria。

Win10 字体不下载，也不写进 Nix 文件。`orion.fonts.windows.enable` 为 true 时，`pkgs.runCommand` 把该目录顶层的 `*.ttf` 和 `*.otf` 复制进 `fonts.packages`。

## 开关和默认值

`orion.fonts.windows.enable` 默认 false。`orion.fonts.windows.directory` 默认是 `users.users.jimmywang0417.home` 下面的 `.local/share/fonts/windows`。把你自己的字体放进这个目录再打开开关。

开关保持 false 时，目录不存在或是空的都不会让构建失败。打开之后，求值要加 `--impure`，否则 flake 看不到这个目录。目录仍然不存在时构建会停。目录在但没有 `*.ttf` / `*.otf` 时只告警，不失败。

## 相关文件

- `modules/fonts.nix`
- `modules/chinese.nix`
- `.gitignore`
- `hosts/orion/default.nix` 不打开这个开关

## 依赖

Noto CJK、Carlito、Caladea 来自这份锁住的 nixpkgs。Win10 字体只来自本机目录。不使用 `nur.repos.rewine.ttf-ms-win10`、`nur.repos.chillcicada.ttf-ms-win10`、`nur.repos.DzmingLi.windows-fonts`，也不 `fetchurl` / `fetchFromGitHub`。

## 未办或不迁

不把字体文件提交进 git。不另装一份 `source-han-sans`，Noto CJK 已经是这份字体。不把 Microsoft YaHei 写进默认回退链。
