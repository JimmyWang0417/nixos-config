# 候选：用户数据快照与独立备份

状态：用户决定暂不启用，仅保留方案。没有配置 Snapper/Restic 服务、定时任务、
云盘授权或备份仓库。本文件也不代表已完成备份。

## 目标与分工

NixOS 历史代恢复系统软件和配置，不能找回被删除的文档。
Orion 的 `/home` 是独立 Btrfs 子卷，可考虑 Snapper 提供短期文件历史；
Restic 则备份到另一块盘、NAS 或远端，覆盖本机硬盘损坏等情况。
同盘快照和独立备份解决的问题不同。

Snapper 已用于 openSUSE/SUSE 的默认快照集成，Restic 是成熟的独立备份项目。
没有可靠的 NixOS 用户使用率数据，也不能把两者组合称为 NixOS 的统一默认方案。
本建议依据现有磁盘布局和恢复需求，而非声称多数人如此配置。

## 空间预算

- 快照创建时主要增加元数据，后续占用取决于保留的旧数据块；修改、删除大文件
  也可能保留大量数据。没有固定“占用磁盘百分之几”的答案。
- Restic 首次保存选中的全部数据，之后主要增加独有变化；压缩和去重效果取决于内容。
- 示例而非本机测量：100 GiB 选定数据、每天 2 GiB 独有变化、保留一周，
  可先按快照额外约 14 GiB、独立备份约 114 GiB 估算，再预留元数据与维护余量。
- 不给现有自适应 Nix GC 额外权限去删除快照或备份；两者需要各自的保留政策。

## 候选目标

若已有足够 Google Drive 配额，可通过 Restic 的 rclone backend 直接读写：
仓库地址的形式为 `rclone:<remote>:<directory>`。无需把网盘挂载成本地文件系统，
也不通过普通同步工具并发同步正在写入的本地 Restic 仓库。
Google Drive 与 Google Cloud Storage 是不同服务。

Google Drive 上保存的是 Restic 加密仓库；密码必须有独立的恢复副本。
OAuth 登录和 token 刷新由 rclone 处理，凭据不得写入公开 Git 或 Nix store。
是否复用现有 rclone 运行时配置，要等启用前确认 remote、可写授权和可用配额，
不推测现有账号权限。

若没有现成云端空间，可先用独立外置硬盘或可用 NAS，确定实际备份量后再决定
是否增加异地副本。目标选择还取决于上传速度、恢复速度、容量和长期费用。

## 启用前需要确认

1. 选定文档、代码、重要应用配置等数据范围；排除缓存、可重新下载的工具链、
   构建产物和大型游戏文件，避免备份成本随这些内容增长。
2. Snapper 对子卷做快照，不能把 Restic 的文件排除规则直接套用到快照上。
   先核对 `/home` 中大型缓存的子卷布局，不在现有盘上直接改分区。
3. 明确保留天数、次数、磁盘余量以及目标目录；确认云端配额或独立盘已挂载。
4. 备份密码和授权安全存放，配置失败通知；创建少量测试备份并验证可恢复后再定时。
5. 独立模块实现，显式 enable，不把候选配置混入默认系统。

参考：[Snapper 在 openSUSE 中的应用](https://doc.opensuse.org/documentation/tumbleweed/snapper/)、
[Restic](https://restic.net/)、
[Restic rclone backend](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#other-services-via-rclone)、
[rclone Google Drive](https://rclone.org/drive/)。
