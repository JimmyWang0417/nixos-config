# Nix 存储维护

`modules/core/nix-storage/` 把三类维护分别放在 `gc.nix`、`adaptive-gc.nix`
和 `optimise.nix`，默认随 `orion.nix.enable` 开启；可用
`orion.nix.storage.enable = false` 关闭这组策略。

## 自适应空间阈值

Nix 的 `min-free`、`max-free` 接受字节数，不接受百分比。因此在每次
`nix-daemon` 启动前，Python helper 对真实 `/nix/store` 执行 `statvfs`，
按其所在文件系统的总容量计算：

- 触发值：容量的 5%，通常限制在 2–16 GiB。
- 目标值：容量的 10%，通常限制在 4–32 GiB。
- 特别小的文件系统：上述值分别不超过容量的 10%、20%，避免固定下限占满磁盘。

例如，100 GiB 文件系统使用 5/10 GiB；1 TiB 文件系统使用 16/32 GiB。
这些比例和边界是本项目的选择，不能当成官方推荐常量。计算不依赖开发主机的
磁盘容量，不在 Nix 求值时读取磁盘，也不根据一时的可用空间反复降低触发标准。

结果以原子替换方式写入 `/run/nix-adaptive-gc/settings.conf`，权限 0644；
目录由 systemd 为 daemon 创建并管理。`nix.conf` 使用 `!include` 加载它，
在构建环境缺少这个运行时文件时允许跳过。生成失败会明确阻止 daemon 启动，
不会静默沿用半写入的配置。

Nix 在构建期间发现可用空间低于触发值时自动回收，达到目标值或没有垃圾时停止。
这不是后台持续监控任务，也不能保证腾出目标空间：历史代、项目缓存等 GC roots
仍然引用的软件不能回收。该机制不删除历史代，也不移除用户的 `result` 链接。

容量在每次 daemon 启动时重算。扩容后若不重启机器，可在没有构建任务时执行
`sudo systemctl restart nix-daemon` 更新阈值；没有为此设置周期性重启，
避免中断构建。使用文件系统总容量不等于识别 Btrfs qgroup 限额、薄置备池剩余量
或全部物理分配限制，仍需关注文件系统本身的空间状态。

## 历史代与去重

每周运行 `--delete-older-than 30d`，保留现有年龄清理规则。
GRUB 最多显示 20 代；它不规定实际必须保留多少代。
自动空间回收与每周历史代清理各自独立，不会因低空间提前缩短 30 天策略。

每周一 04:00（按机器本地时区，附加上游默认随机延迟）运行 store 去重。
使用上游的空闲 CPU/IO 调度与交流电条件；定时器持久化，关机错过后可补跑。
去重把内容相同的 store 文件改为硬链接，不减少可回滚的系统代数。
不启用每次写入 store 时去重，以免增加每次构建的等待。

手动检查当前阈值与 GC roots：

```sh
cat /run/nix-adaptive-gc/settings.conf
nix-store --gc --print-roots
systemctl list-timers nix-gc.timer nix-optimise.timer
```

仅检查输出，不自动删除用户目录的链接。用户数据快照和独立备份仍是另外的议题，
本次没有部署 Snapper/Restic 或进行实际垃圾回收。

依据：[Nix 的 min-free/max-free](https://nix.dev/manual/nix/stable/command-ref/conf-file.html#conf-min-free)、
[官方 Wiki 的 store 去重与清理](https://wiki.nixos.org/wiki/Storage_optimization)。
