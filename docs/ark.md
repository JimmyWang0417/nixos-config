# Ark 中文 ZIP 与解压后端

`modules/programs/ark.nix` 提供 `orion.archives.ark`，Orion 明确开启。
`packages/ark/` 只处理包和私有依赖；不把归档处理逻辑塞进桌面软件清单。
Ark、libzip 和命令行后端均来自同一锁定 unstable 包集。

## 中文文件名

旧 Windows ZIP 常没有声明文件名编码。原生 libzip 可能把 GBK/GB18030 字节
当作 CP437，导致中文乱码。当前 Ark 没有通用的 `arkrc` 默认编码选项，
改变系统 locale 也不能修复这个解码路径。直接给 Linux 版官方 7zz 加数字
代码页参数，在本次实际测试中同样无效。

本配置保留 Ark 的原生 libzip ZIP 插件，为它单独构建一份私有 libzip：

- 保留 ASCII、已识别的 UTF-8、Unicode 文件名额外字段与 RAW 字节访问。
- 只有原本将按 CP437 处理的字符串才尝试严格 GB18030 解码，涵盖 GBK。
- 非法或不完整的 GB18030 序列仍回退到原来的 CP437 行为。
- 列表、按文件名定位和解压都经过同一转换，不只修正界面显示。

不会在启动时重写原压缩包，也不改变其他应用使用的系统 libzip。
新建 ZIP 仍使用正常 Unicode 文件名。

**没有编码标记的字节无法被完全可靠地识别。** 部分 CP437、Big5、Shift-JIS
名称可能与合法 GB18030 字节重合；无标记且恰好是合法 UTF-8 的字节也具有歧义。
处理非中文旧档案时，可关闭本回退并重建：

```nix
orion.archives.ark.legacyChineseZip = false;
```

这会使用原生 libzip 的编码行为；不是新增一个上游 Ark 不认识的配置键。
长期交换文件时应优先使用带正确 UTF-8 标记的 ZIP。

## 插件和后端

在 Ark 现有 Qt wrapper 中加入私有命令行后端路径，保留原有 Qt 插件、桌面入口
和 D-Bus 启动方式。官方 7zz 在这里以 Ark 要求的 `7z` 命令名提供；RAR 解压
使用 unrar/unar，ZIP 辅助工具和常见压缩过滤器也由包闭包提供。
ranger 调用系统提供的 `7zz`。Ark 的 `7z` 别名只在 Ark 的后端路径中使用。

系统 `/etc/xdg/arkrc` 通过原生 `Plugins.disabledPlugins` 键清空旧的禁用列表，
该项由 Nix 固定；其他 Ark 偏好保留。插件仍进行上游的可执行文件和库可用性检查。
提供 RAR 读取后端不等于提供专有的 RAR 创建程序。

验证运行真实 Ark 的 offscreen 批量解压、文件名与内容比对、libzip 按名定位和
按索引读取，覆盖 GBK、四字节 GB18030、UTF-8 有无标记、Unicode extra 字段、
混合档案、CP437 回退、TAR、7z 和新建 ZIP。测试只使用临时目录与独立 XDG
配置，不加载当前桌面，不改用户 HOME，也不下载用户插件。

```sh
nix build --no-link .#checks.x86_64-linux.ark-archives
```

依据：[Ark 的原生配置项](https://github.com/KDE/ark/blob/v26.08.3/kerfuffle/ark.kcfg)、
[ZIP 插件](https://github.com/KDE/ark/blob/v26.08.3/plugins/libzipplugin/libzipplugin.cpp)、
[插件说明](https://github.com/KDE/ark)、
[libzip 编码接口](https://libzip.org/documentation/zip_get_name.html)。
