这里只登记以后要加密的名字。仓库里没有密文，也没有私钥。

sops-nix 在开机时用本机 `~/.config/sops/age/keys.txt` 和 `/etc/ssh/ssh_host_ed25519_key` 解密到 `/run/secrets`。私钥不要提交。

还没有 age 收件人。在要开始加密时执行：

```
ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
```

把打印出来的 `age1...` 写进仓库根目录的 `.sops.yaml`，再对单独的文件运行 `sops`。不要把词库、许可证、订阅、Wi-Fi 密码或令牌原文贴进 Git。
