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

依据：[Syntastic 归档状态](https://github.com/vim-syntastic/syntastic)、
[coc-clangd 使用说明](https://github.com/clangd/coc-clangd#quick-start)、
[coc-clangd 路径选择实现](https://github.com/clangd/coc-clangd/blob/master/src/install.ts)。
