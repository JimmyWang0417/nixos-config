# Node/npm 的用户目录

用户默认路径分成四个职责，shell 与 systemd 用户服务使用相同变量：

- `NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc`：可写配置与凭据。
- `NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm`：下载缓存与日志。
- `NPM_CONFIG_PREFIX=$XDG_DATA_HOME/npm`：用户全局安装的软件与 `bin/`。
- `NODE_REPL_HISTORY=$XDG_STATE_HOME/node/repl_history`：交互历史。

未指定 XDG 根目录时分别使用 `~/.config`、`~/.cache`、`~/.local/share`、
`~/.local/state`。`HOME` 保持原值。全局 npm 的 `bin` 放在 PATH 最后，避免覆盖
Nix 管理的同名命令；项目局部 `node_modules/.bin` 的正常机制不变。

## 配置与迁移

`home/modules/development/node/` 独立提供环境、POSIX shell 路径整理和迁移脚本。
Home Manager 写入边界后执行迁移，dry-run 不移动数据。旧 `.npm`、`.npm-global`、
`.npmrc` 与 `.node_repl_history` 只在目标不存在时重命名；保留目录内的相对链接、
文件内容、时间戳和权限，npmrc 与历史文件收紧为 0600。不读取或把 npmrc 凭据
写入 Nix store，不重装全局软件。

迁移激活步骤显式导出这四个变量，并让 Neovim 插件安装步骤排在其后；首次激活
尚无登录 shell 时，Coc/npm 也会使用新目录，而不是重新创建 `~/.npm`。
若独立复用 Neovim 模块而未导入 Node 模块，则不增加这个 DAG 依赖。

使用 Linux `renameat2(RENAME_NOREPLACE)` 避免覆盖并发创建的目标。遇到冲突、符号
链接、特殊文件、跨文件系统或引用旧目录的活跃进程时保留原数据并报告，不自动
合并、删除或留下家目录兼容链接。首次迁移前应退出使用旧全局软件路径的进程。
缓存跨盘时也不做隐式大规模复制；需要另外安排迁移。

迁移后的 npmrc 内容保持原样，历史 `prefix` 配置会被声明的 `NPM_CONFIG_PREFIX`
覆盖；凭据仍由 npm 从可写的指定文件读取。后续 `npm install -g` 使用新目录。
不添加现代 npm 不支持的 `devdir` 设置，node-gyp 使用其现有 XDG 行为。

当前主机没有家目录根下的 `package.json` 或 `node_modules`，不添加阻止在家目录
运行 npm 的额外命令包装器。目录布局解决的是应用状态归属，并不禁止正常项目操作。

## 当前 Manjaro 会话

当前主机另外使用 `~/.config/node/env.sh`，由 Zsh 的启动入口加载；
`~/.config/environment.d/30-node-xdg.conf` 保存四个环境变量供后续用户服务会话使用。
当前 Zsh 在 `.zshenv` 与原有 `.zshrc` 前缀位置加载该文件，非交互命令也能获得新路径。
迁移前的 shell 文件及私有配置/历史副本保存到用户状态目录的私有备份中，源码仓库
只保存无凭据的迁移规则。已运行的进程不会被强制改写环境；新终端和重启后的应用
使用新路径，非 Zsh 的旧进程需重新启动或显式继承这些变量。
已经打开的终端可执行 `source ~/.config/node/env.sh`；无法从外部强制改写其父进程环境。

验证包括临时目录中的原样迁移、目标竞争、冲突/链接保留、跨盘处理、活跃进程
延期、重复运行、dry-run，以及不改变 HOME 的 PATH 优先级检查。实际 npm 的离线
本地包测试确认普通项目和显式 `--prefix` 项目仍各自在自己的目录生成
`node_modules`/lockfile，不会因为全局前缀环境变量改成全局安装。
