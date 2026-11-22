# Neovim 诊断与 C/C++ 工具

Neovim 继续使用现有 Coc、vim-plug、主题和快捷键。移除已经归档的
Syntastic 声明，代码诊断统一通过 Coc 及其语言服务器提供；不另加一套原生
LSP 或 lint 插件。Coc 中针对 Vim、eruby、Markdown 的 EFM 配置保留。

C/C++ 只由 `coc-clangd` 扩展连接 clangd，删除原来在
`languageserver.coc-clangd` 中重复注册的通用服务器。扩展会按项目的
`.clangd`、`compile_commands.json` 或 `compile_flags.txt` 等文件定位项目。

`clangd.path = "clangd"` 明确从 Neovim 包装器的 PATH 查找命令，而不使用
扩展缓存目录里以前下载的 clangd。`home/modules/editors/neovim.nix` 已将
同一 unstable 包集的 `clang-tools` 加入该 PATH；`clangd.checkUpdates = false`
关闭扩展的语言服务器更新检查。clangd 本体随 Nix 包更新，常规配置不调用
`:CocCommand clangd.install`。项目自己的 Coc 配置仍可覆盖用户配置。

插件清单现为 17 个 vim-plug 插件、12 个 Coc 扩展；`coc-clangd` 扩展保留。
激活安装器继续只安装缺失项。移除声明后 vim-plug 不再加载 Syntastic，旧的
`plugged/syntastic` checkout 不会自动删除。确认不需要时可另行使用 `:PlugClean`。

## F3–F7 快速操作

`command.vim` 只组合 `commands/common.vim`、`format.vim`、`build.vim`、
`run.vim` 并保留原有函数名。`keyboard.vim` 只声明按键，不再重复定义函数；
重新加载配置时不会重复定义报错。init 仍先声明 Coc 扩展，再加载插件和界面，
最后加载原有按键；各文件从配置入口所在目录定位，路径含空格也能加载。

- **F3**：格式化当前缓冲区。C/C++ 使用 `clang-format`，Python 使用独立
  `black` 命令，shell 使用 `shfmt`。内容通过标准输入传给格式化器，不运行
  脚本、不自动保存，未命名缓冲区也可格式化。失败保留原缓冲区并显示错误。
- **F5**：先保存已命名缓冲区，再构建或检查。C 使用 `gcc` 与 C17，C++ 使用
  `g++` 与原来的 C++14；Python 用 `python3 -m py_compile`，shell 用
  `bash -n`。Python/shell 此时只检查语法，不再意外执行脚本。
- **F6**：先保存当前文件，在新终端窗口运行已有 C/C++ 程序、Python 或
  shell 脚本，可正常交互输入。Python 使用当前 PATH 的 `python3`，从已允许的
  direnv 项目终端启动 Neovim 时可以使用该项目的解释器。
- **F7**：先执行 F5 的构建或语法检查，成功后再运行一次；构建失败不会启动
  旧的可执行文件。

C/C++ 输出仍放在源文件旁，去掉最后一个扩展名；源文件没有扩展名时追加
`.out`，避免覆盖源文件。F5/F7 是单文件快捷操作，多文件项目仍使用项目的
构建系统。Python 语法检查会产生正常的 `__pycache__` 缓存。

所有工具和程序均以参数列表直接启动，文件名不会拼进 shell 命令；空格、中文、
引号及 shell 特殊字符都作为路径内容处理。未命名缓冲区需先命名才能构建或运行，
无法保存时不启动工具。格式化与构建最多等待 30 秒，程序运行保留交互终端。

原有 `i/j/k/l` 导航、主题、Coc 补全及 F3/F5/F6/F7 键位保留；Nix 包装器提供
`black`、`clang-format`、`shfmt`，不再依赖当前 Python 环境恰好安装 Black。
隔离的 headless 测试覆盖命令选择、路径参数、格式化不执行脚本、失败不覆盖缓冲区、
未保存文件处理和构建失败不运行旧程序；测试不会下载或运行用户的真实插件。

依据：[Syntastic 归档状态](https://github.com/vim-syntastic/syntastic)、
[coc-clangd 使用说明](https://github.com/clangd/coc-clangd#quick-start)、
[coc-clangd 路径选择实现](https://github.com/clangd/coc-clangd/blob/master/src/install.ts)。
