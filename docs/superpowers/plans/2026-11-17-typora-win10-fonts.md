# Typora 与 Windows 10 字体 Implementation Plan

> **For agentic workers:** 按下面的任务执行；本任务已获用户实施授权，文档与字体来源核对可并行完成。

**Goal:** 在 Orion 配置中安装自有 NUR 的 Typora 和社区 NUR 的 Windows 10 字体，并同步说明。

**Architecture:** 软件包模块显式引用自有 NUR Typora，字体模块接受可选字体包，主机选择具体字体来源。本机字体目录接口继续保留。

**Tech Stack:** Nix flakes、NixOS 26.05、NUR、Home Manager、fontconfig。

## Global Constraints

- 对外软件包名为 `typora`，字体包名为 `ttf-ms-win10`。
- 仅更新 `nur-packages` 输入，不刷新其他输入。
- 不激活系统，不改变字体默认回退和 Markdown 默认程序。
- 使用隔离 worktree，发布前同步上游，不提交 `nvim.log` 或字体文件。

---

### Task 1: 配置和固定输入

**Files:** `flake.nix`、`flake.lock`、`modules/packages.nix`、`modules/fonts.nix`、`hosts/orion/default.nix`。

**Interfaces:** 输入 `inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.typora`；输出系统 Typora 和 `fonts.packages` 中的字体包。新增 `orion.fonts.windows.package`，默认 `null`；原 `enable`、`directory` 保持含义。

- [x] 更新自有 NUR URL 为 `github:JimmyWang0417/nur-packages/9a4bcf65fac8de0738e002e8bfe00a68ac4019b6`，执行 `nix flake lock`，核对锁文件仅更改该节点。
- [x] 在软件包模块加入 `inputs` 参数、`nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};`，包列表加入 `nurPkgs.typora`。
- [x] 字体模块添加 `package` 选项，通过 `lib.optional (cfg.package != null) cfg.package` 合并入 `fonts.packages`；主机设置 `orion.fonts.windows.package = pkgs.nur.repos.chillcicada.ttf-ms-win10;`。
- [x] 用 `nix eval --json .#nixosConfigurations.orion.config.environment.systemPackages --apply 'ps: map (p: p.name) (builtins.filter (p: (p.pname or "") == "typora") ps)'` 核对仅有目标 Typora，并求值 `config.fonts.packages` 核对字体名称。

### Task 2: 文档、验证与发布

**Files:** `README.md`、`docs/fonts.md`、`docs/packages.md`、`inventory/functions.md`、`inventory/unmapped.md`、`inventory/适配清单.md`。

**Interfaces:** 说明已启用的包和可覆盖入口，记录真实版本与来源；本机字体导入仍默认关闭。

- [x] 更新文档，删除与用户授权相矛盾的 Typora 和 Win10 字体“暂不迁”说明，保留原始软件清单。
- [x] 执行 `nix eval --raw .#nixosConfigurations.orion.config.system.build.toplevel.drvPath` 和失败断言检查，确认整个 Orion 配置求值通过。
- [x] 构建所选 Typora 和字体 derivation，用 fontconfig 核对字体文件可识别；不重新安装或激活当前系统。
- [x] 执行 `git diff --check`、核对来源和文档引用，提交目标文件；同步 `origin/master` 后普通推送并核对远端提交。

## 验证结果（2026-11-17）

- Orion 整机 toplevel derivation 求值通过，失败断言列表为空。
- 系统包仅选中自有 NUR 的 `typora-0.11.18-plugin-1.19.16`，构建通过。
- `ttf-ms-win10-unstable-2021-02-10` 构建通过，144 个文件均被 fontconfig 识别，共 196 个字体样式；微软雅黑、宋体、Consolas 等按名匹配正确。
- 字体包选项设为 `null` 时，不再加入 Win10 包，本机目录开关仍为 false。
- 锁文件仅更新自有 `nur-packages` 节点，文档和 diff 格式检查通过。
