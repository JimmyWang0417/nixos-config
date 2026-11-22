# VS Code

## 作用

`home/editors.nix` 只导入三个独立模块：`home/modules/editors/vscode.nix`、`neovim.nix`、`ranger.nix`。VS Code 的程序、扩展、设置、快捷键和依赖集中在 `vscode.nix`。

home-manager 启用 `programs.vscode`，包是 `pkgs.vscode`。`environment.systemPackages` 里不再放一份。已装扩展里，当前 unstable 包集有 `pkgs.vscode-extensions.<publisher>.<name>` 的，写在 `programs.vscode.profiles.default.extensions`。home-manager 把 `programs.vscode.extensions` 改到了这个名字。

2026-11-22 对照本机实际文件：原有 26 个 settings 顶层键全部已经迁入，两个快捷键与本机相同；本机 snippets 目录为空，也没有额外 VS Code profiles。迁移没有复制认证数据、扩展缓存或机器标识。

设置文件由 `programs.vscode.profiles.default.userSettings` 读取 `home/vscode/settings.json`，再合并 JDK 的 Nix 路径和 LaTeX 构建方案；快捷键由 `keybindings` 引用 `home/vscode/keybindings.json`。Ayu Light、Catppuccin Latte 图标、自动保存、Markdown 预览、终端字号、Git 行为与原来的快捷键保留。`verilog.ctags.path` 从本机 `/usr/bin/ctags` 改为 `ctags`，通过 Nix profile 找到 `universal-ctags`；`update.mode = "none"` 由 Nix 管理程序更新。

本机 `~/.vscode/argv.json` 的 `locale = "zh-cn"` 此前遗漏，现由 `programs.vscode.argvSettings.locale` 声明，中文语言包仍在扩展列表里。没有复制 `crash-reporter-id`。

## 开关和默认值

`programs.vscode.enable = true`。`programs.vscode.package = pkgs.vscode`。扩展列表没有单独开关。`mutableExtensionsDir` 保持模块默认：只声明 default profile 时为 true，Nix 链接已映射的扩展。

## Verilog 检查与格式化

本机配置使用 Icarus Verilog 检查，但旧的软件清单漏装了命令 `iverilog`，现在由 VS Code 模块安装 `pkgs.iverilog`。原来的默认格式化扩展 `ericsonj.verilogformat` 不在锁定 nixpkgs 的扩展集中，其外部 `verilog-format-git` 已由用户卸载，不重新装回。

Verilog 和 SystemVerilog 改由已有的 `mshr-h.veriloghdl` 扩展调用 `pkgs.verible` 的 `verible-verilog-format`，使用该扩展实际声明的 `verilog.formatting.verilogHDL.formatter`、`verilog.formatting.systemVerilog.formatter` 和 `verilog.formatting.veribleVerilogFormatter.path`。没有设置自动格式化保存，保留手动格式化的使用方式。

## 语言工具链

扩展与编译工具分别核对，不能把安装扩展当作已有编译器。VS Code 模块提供 GCC、Cargo、rustc、rustfmt，以及前述 Icarus Verilog 和 Verible。Java 使用系统已有的 JDK，并按 Oracle Java 扩展的真实选项 `jdk.jdkhome` 指向 `pkgs.jdk.home`。

LaTeX Workshop 使用`texliveSmall.withPackages` 在小型方案上增加 `latexmk`、`xetex`、`ctex`、`xecjk`、`biblatex`、`biber`、`fandol`。Fandol 为 `ctexart` 提供默认中文字体；没有安装 `scheme-full`，也不使用已弃用的 `texlive.combine`。默认构建方案是 `latexmk (XeLaTeX)`，另保留 `latexmk (pdfLaTeX)`，命令指向这份 TeX 包的绝对路径。项目自己的 `.latexmkrc` 仍由 latexmk 读取。

锁定 nixpkgs 的扩展打包已经把 Tinymist 的 `tinymist.serverPath` 和 Rust Analyzer 的 `rust-analyzer.server.path` 指向各自的 Nix 服务程序，无需再声明一份下载器。Python 解释器和 ESLint/npm 依赖保持项目选择，不把本机某个项目环境写成所有项目的默认解释器，也不全局安装 npm 项目依赖。

## 相关文件

- `home/modules/editors/vscode.nix`
- `home/vscode/settings.json`
- `home/vscode/keybindings.json`
- `home/modules/editors/neovim.nix` 与 `ranger.nix` 分别管理另外两个编辑器
- `modules/packages.nix` 不再列入 `vscode`

## 依赖

扩展来自全局锁定的 nixos-unstable 包集，与 VS Code 和系统使用同一来源，不钉本机 marketplace 版本，也不跟 pre-release。`anthropic.claude-code`、`ms-vscode.cpptools`、`ms-vscode.remote-explorer`、`ms-python.vscode-pylance`、`ms-vscode-remote.remote-ssh`、`ms-vscode-remote.remote-ssh-edit` 是 unfree，沿用已经打开的 `allowUnfree`。`code` 在用户 profile 里，`rifle.conf` 仍调用它。

## 未办或不迁

对照当前实际安装的 56 个扩展，32 个有锁定 unstable 的属性并已声明；下面 24 个没有对应属性，不自动复制本机扩展目录或打包未知 VSIX。需要单独补充时应核对发布来源与许可证。列表中的 `ericsonj.verilogformat` 已有上面的可用格式化替代路径。

- `affenwiesel.matlab-formatter`
- `atomgit-cloudenv.cannlabdevspace`
- `beardedbear.beardedicons`
- `czhang03.unicode-math-input`
- `dbcode.dbcode`
- `ericadamski.carbon-now-sh`
- `ericsonj.verilogformat`
- `huaweicloud.developerspace`
- `kevinrose.vsc-python-indent`
- `kkaaddff.arkts-ets`
- `liviuschera.noctis`
- `mathworks.language-matlab`
- `matthewevers.compiler-explorer`
- `mkxml.vscode-filesize`
- `ms-toolsai.vscode-jupyter-powertoys`
- `ms-vscode.cpp-devtools`
- `ms-vscode.cpptools-themes`
- `ms-vscode.wasm-wasi-core`
- `openai.chatgpt`
- `openai.codex-audio`
- `openlibing.resourcemanager`
- `perkovec.emoji`
- `starcatmeow.vjudge-helper`
- `wavetrace.wavetrace`
