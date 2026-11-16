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
