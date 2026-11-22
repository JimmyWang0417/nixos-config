密文用 sops-nix 和 age 加密。私钥在本机 `~/.config/sops/age/keys.txt`，不入库。开机后解密到 `/run/secrets/<名字>`，权限 0400，属主 jimmywang0417。每个文件是该事项的 tar，里面只有文件名，没有说明文字。

| secret 名 | 运行时路径 | 内容种类 |
| --- | --- | --- |
| fcitx5-pinyin | /run/secrets/fcitx5-pinyin | 拼音 user.dict 与 user.history |
| clash-verge | /run/secrets/clash-verge | 订阅 profile、profiles.yaml、clash-verge.yaml、.encryption_key |
| anytls-ssh-key | /run/secrets/anytls-ssh-key | 一份 anytls 用的 ed25519 私钥 |
| rclone-webdav | /run/secrets/rclone-webdav | 整份 rclone.conf。里面只有一个名为 webdav 的 remote，没有拆开 |
| jetbrains-licenses | /run/secrets/jetbrains-licenses | JetBrains 的 *.key 和 plugin_*.license |
| wps-license | /run/secrets/wps-license | WPS license2.dat |
| botmux-bots | /run/secrets/botmux-bots | bots.json |
| nm-connections | /run/secrets/nm-connections | NetworkManager 系统连接 |
| cc-switch | /run/secrets/cc-switch | CC Switch 的 cc-switch.db |

不入库：alder、crm、udf-http-range-proxy、keepassxc-unlock、verilog-format、xjtu-course-genius、xjtutoolbox、botmux 程序本身、animeko、EasyConnect、华为云会议、Anaconda、Grok Bot、Typora、Win10 字体。v2rayN 的 guiConfigs 也没有打进密文。

## 运行时恢复

密文声明在 `modules/core/secrets.nix`。`home/modules/private/` 在用户服务重载前
恢复 Clash、rclone、JetBrains、botmux 和 CC Switch；公开偏好初始化排在恢复之后。
`home/fcitx5/` 单独恢复学习词库。root 服务 `orion-private-configs` 在
NetworkManager 启动前恢复系统连接，并把 WPS 的 `license2.dat` 放到实际的
`/opt/kingsoft/.auth`。secret 使用 systemd 解密时，恢复逻辑会等待对应单元。

共享恢复程序位于 `lib/restore-private-archive.py`：先校验整个归档，拒绝越界路径、
链接和特殊文件，使用私有临时文件和原子的不覆盖发布。原有文件、权限、数据库
WAL 和 Clash 配套密钥状态均保留；缺少解密结果时报告并跳过。
这些脚本不会在求值或构建时读取私有文件。

JetBrains 归档保留原产品版本目录，并不保证旧授权适用于新 IDE；WPS 授权也应由
客户端确认。anytls 私钥归档仅保留，未声明包含私人目标的隧道单元。
