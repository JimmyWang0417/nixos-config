# VS Code

## 作用

home-manager 启用 `programs.vscode`，包是 `pkgs.vscode`。`environment.systemPackages` 里不再放一份。已装扩展里，nixos-26.05 有 `pkgs.vscode-extensions.<publisher>.<name>` 的，写在 `programs.vscode.profiles.default.extensions`。这份 home-manager 把 `programs.vscode.extensions` 改到了这个名字。

`~/.config/Code/User/settings.json` 没有扩展推荐，也没有 token。`keybindings.json` 同样没有。两份都链接到家目录。`verilog.ctags.path` 写成 `ctags`，用系统包里已有的 `universal-ctags`。

## 开关和默认值

`programs.vscode.enable = true`。`programs.vscode.package = pkgs.vscode`。扩展列表没有单独开关。`mutableExtensionsDir` 保持模块默认：只声明 default profile 时为 true，Nix 链接已映射的扩展。

## 相关文件

- `home/editors.nix`
- `home/vscode/settings.json`
- `home/vscode/keybindings.json`
- `modules/packages.nix` 不再列入 `vscode`

## 依赖

扩展来自这份锁住的 nixos-26.05，不钉本机 marketplace 版本，也不跟 pre-release。`anthropic.claude-code`、`ms-vscode.cpptools`、`ms-vscode.remote-explorer`、`ms-python.vscode-pylance`、`ms-vscode-remote.remote-ssh`、`ms-vscode-remote.remote-ssh-edit` 是 unfree，沿用已经打开的 `allowUnfree`。`code` 在用户 profile 里，`rifle.conf` 仍调用它。

## 未办或不迁

下面这些没有 nixpkgs 属性。不打包 VSIX。

- `affenwiesel.matlab-formatter`
- `atomgit-cloudenv.cannlabdevspace`
- `beardedbear.beardedicons`
- `czhang03.unicode-math-input`
- `dbcode.dbcode`
- `ericadamski.carbon-now-sh`
- `ericsonj.verilogformat`
- `huaweicloud.developerspace`
- `kevinrose.vsc-python-indent`
- `kkaaddff.arkts-ets`
- `liviuschera.noctis`
- `mathworks.language-matlab`
- `matthewevers.compiler-explorer`
- `mkxml.vscode-filesize`
- `ms-toolsai.vscode-jupyter-powertoys`
- `ms-vscode.cpp-devtools`
- `ms-vscode.cpptools-themes`
- `ms-vscode.wasm-wasi-core`
- `openai.chatgpt`
- `openai.codex-audio`
- `openlibing.resourcemanager`
- `perkovec.emoji`
- `starcatmeow.vjudge-helper`
- `wavetrace.wavetrace`
