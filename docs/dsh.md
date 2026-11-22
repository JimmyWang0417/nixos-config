# DSH 模块

DSH 的配置位于 `modules/programs/dsh/`。`modules/dsh.nix` 保留兼容入口，`modules/programs/default.nix` 负责导入。包来自全局 unstable 的 `pkgs.deepseek-harness`，通过原有 `orion.packages.unstable` 列表安装；这里不再创建另一套 nixpkgs，也不维护独立的 npm 系统包。

## 文件职责

`default.nix` 组合选项、运行时逻辑和插件清单。`options.nix` 保留公共接口 `orion.packages.dshPlugins`，类型仍为字符串列表，选项默认值为 `[]`；当前模块选择的 38 个插件由 `plugins/default.nix` 组合。

`runtime.nix` 负责检查 DSH 是否已列入软件清单，并在 Home Manager 的 `writeBoundary` 之后运行协调脚本。实际处理位于 `reconcile-plugins.py`，避免把 Python 和 Nix 配置混在一个长表达式内。该模块安装插件，不自动启动 DSH web 会话或增加后台服务。

## 插件分组

`plugins/default.nix` 明确列出以下顺序。每个分组文件只返回插件名称列表：

- `core.nix`：dsh-market 与侧栏工作区。
- `context.nix`：上下文查看、费用与启动 cookie 防护。
- `workbench.nix`：技能/MCP、交互组件、配置、浏览器、搜索与文件工具。
- `interaction.nix`：快速输出、邮件和移动端入口。
- `models.nix`：免费模型入口和重试设置。
- `behavior.nix`：验收循环、人设与本地长期记忆。
- `connectors.nix`：WorkBuddy、Qoder、Trae、Codex 连接器。
- `chat.nix`：侧问与 QQ 通道。
- `reading.nix`：论文伴读、翻译、文库与论文到产品流程。
- `bibliography.nix`：引文与 Zotero。
- `writing.nix`：LaTeX、学位论文与研究技能。
- `learning.nix`：辅导、课程规划与学术学习。
- `slides.nix`：幻灯生成。

这次拆分保留了原有 38 个名称及其顺序。增加插件时，把真实的包名或既有支持的 registry spec 加到所属组，并确认它支持锁定的 DSH 版本；不在名称后附加版本。新增一组时，必须把文件加入 `plugins/default.nix`，不能只创建文件。

## 激活与更新

脚本优先使用 `DSH_HOME`，未设置时使用 `~/.dsh`，协调的 profile 是 `web`，依赖清单位于 `profiles/web/package.json`：

1. 已列入依赖键或已保存 spec 的 registry 插件保留，激活不会无条件重装。
2. 清单中新出现的名称通过 `dsh plugin --profile web add` 安装。
3. 不再被名称或 spec 列表引用的依赖通过 `dsh plugin --profile web remove` 移除。
4. 仍在清单里的 `link:`、`file:` 依赖先移除，再以清单名称重新安装，避免把旧 Nix store 路径当作可更新的插件。

插件版本由 dsh-market 后续管理，flake 不锁它们的 registry 版本。`nix flake update` 更新 Nix 输入，不能据此声称全部已安装插件也更新了。锁定的 DSH 与最新上游预览版差距见 [软件核对](unstable-migration.md)。当前使用的是 `dsh plugin` 命令，不能把独立的 dsh-market 误写成 `dsh market` 子命令。

需要停用这套插件协调时，可在主机配置中使用：

```nix
orion.packages.dshPlugins = lib.mkForce [ ];
```

空列表会跳过协调，不清空已经存在的 profile。若保留非空列表但移除 DSH 软件，配置断言会失败，提示恢复 `deepseek-harness` 到 `orion.packages.unstable`。自定义列表仍使用原有选项，不需要依赖分组文件的内部实现。

## 用户配置与凭据

2026-11-22 检查时，本机没有设置 `DSH_HOME`，`~/.dsh`、`~/.config/dsh` 和 `~/.local/share/dsh` 均不存在。因此此次迁移可核实的是仓库里已有的插件选择和安装行为，没有声称已复制运行时 provider、模型选择、MCP 账号或插件个人设置，也没有编造默认值。

这些分组不是 provider 设置或用户数据目录。以后出现可迁移的普通设置，应按真实 DSH 版本和文件格式单独建立配置模块，明确是否覆盖已有内容；账号、token、连接器登录信息与会话文件通过已有私有配置/sops 边界处理，不放进插件清单、公开 JSON 或 Nix store。
