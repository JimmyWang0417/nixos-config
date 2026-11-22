# Ranger 文件管理器

保留 Miller 三栏、原有键位、相对行号、配色与 devicons。配置入口仍是
`home/modules/editors/ranger.nix`，资源按 rc、rifle、预览脚本和图标插件分开。

## 编辑与打开

文本文件的默认动作遵循 `${VISUAL:-$EDITOR}`；系统 `EDITOR=nvim`，因此默认
在终端编辑。`E`、`F4` 和 `:edit` 继续使用 Ranger 内置编辑动作。
需要 VS Code 时选择 `:open_with code`，不把 GUI IDE 与终端编辑器的用途混同。
移除的 `my_edit` 只是未被键位引用的上游示例，实际编辑命令没有减少。

## 预览与性能

- 关闭进入目录前的自动条目计数；仍可使用原有 `dc` 手动统计累计大小。
- 单文件自动预览上限为 100 MiB，预览脚本最多运行 5 秒。更大文件仍正常列出，
  但不自动读取预览；需要时可自行调整 `preview_max_size`。
- 小于等于 256 KiB 的文本尝试语法高亮，较大文本交给 Ranger 的受限文本读取。
- 压缩包默认只列目录，不再为了封面预览自动提取其中的图片。7z/ZIP 使用官方
  `7zz`；其他归档使用 atool/libarchive，atool 明确指定 `path_7z=7zz`。
- 保留 PDF 前十页文本、第一页缩略图、视频缩略图、音视频元数据、ODT 和 HTML
  等实际提供的处理器。移除旧脚本中没有对应依赖的字体、电子书等示例分支。
- 只让 Ranger 包装后的 PATH 提供预览依赖，撤销重复的用户软件清单声明；这不是
  声称 Nix 原先存储了两份相同软件。完整 rc 不再重复加载上游默认键位文件。

默认图片协议由 w3m X11 覆盖窗口改为 Sixel。已核对
[锁定的 Konsole 26.08.3 源码](https://github.com/KDE/konsole/blob/v26.08.3/src/Vt102Emulation.cpp)
具有 Sixel 解码，以及
[锁定的 Ranger 实现](https://github.com/ranger/ranger/blob/46e957af9762dd2fcaabfbef4d3c45c16edd1184/ranger/ext/img_display.py)
具有 Sixel 预览器。ImageMagick 编码实际测试通过；实际显示仍需部署后在 Konsole
确认，不能据此保证所有终端或 tmux 都支持。其他终端可用原有 `zi` 关闭图片预览。

## 验证

`tests/ranger.nix` 构建独立测试环境，使用实际 7zz、atool、rifle、Poppler 与
ImageMagick 执行临时文件测试：中文与空格路径、shell 元字符文件名、归档只读预览、
显式解压、文本编辑器参数、PDF 缓存，以及图片编码。预览不运行选中的脚本，
文件名不拼接成 shell 代码。测试不打开 GUI，不把归档解到临时目录之外。
