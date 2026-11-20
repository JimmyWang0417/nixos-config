{ config, lib, pkgs, inputs, hostName, ... }:
{
  imports = [
    ../../modules/hardware.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];

  networking.hostName = "Orion-Laptop";
  system.stateVersion = "26.05";

  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [
    "quiet"
    "udev.log_priority=3"
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "mem_sleep_default=deep"
  ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "thunderbolt"
  ];
  boot.tmp.useTmpfs = true;

  orion.boot = {
    enable = true;
    timeout = 10;
    canTouchEfiVariables = false;
  };
  orion.chinese.enable = true;
  orion.fonts.windows.package = pkgs.nur.repos.chillcicada.ttf-ms-win10;
  orion.nix = {
    enable = true;
    allowUnfree = true;
    chinaMirrors.enable = true;
    # Clash Verge mixed port. HTTP proxy; SOCKS 7898 and HTTP 7899 are disabled.
    proxy = "http://127.0.0.1:7897";
    download.enable = true;
  };
  orion.easyconnect = {
    enable = true;
    # Stopped + probe fails: start. Probe success while stopped: stay stopped.
    # A running container stops only when the active connection is a name
    # below. A later success through the tunnel does not stop it.
    # No PSK was read. Wired "有线连接 1" is not a stop condition.
    campusProbes = [ "https://kq.xjtu.edu.cn" ];
    campusConnections = [
      "XJTU_STU"
      "xjtuse-lab"
    ];
    campusSubnets = [ ];
  };
  orion.secrets.enable = true;
  orion.packages.unstable = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.deepseek-harness # 26.05 没有此包
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.claude-code # 26.05 的 CLI 更旧
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.codex # 26.05 的 CLI 更旧
  ];
  # dshmarket 负责安装和更新，Nix 不钉版本.
  orion.packages.dshPlugins = [
    "dshmarket" # dsh-market。社区插件的安装和更新
    "dsh-better-sidebar" # 文件树、编辑器、改动、任务和侧聊
    "dsh-context" # 只读官方上下文投影，展开组成，不压缩
    "dsh-cost-meter" # 会话费用。官方 session-stats 只计 token
    "dsh-auth-cookie-guard" # 抬高请求头上限，并清掉旧的启动 cookie
    "dsh-skill-mcp-panel" # 侧栏管理技能和 MCP
    "dsh-genui" # 对话里的图表、表单和小组件
    "dsh-config-manager" # 备份、导入和同步 dsh 配置
    "dsh-ego-browser" # 浏览器自动化和观察窗
    "dsh-free-search" # 免费网页搜索
    "dsh-ops" # Linux 上也有的文件和 PTC 工具
    "dsh-fast-mode" # 缩短输出，不压缩上下文
    "dsh-email" # 在 dsh 里收发邮件
    "dsh-mobile" # 手机和局域网访问
    "dsh-our-free-model" # 免登录的 Zen/Kilo 模型。WorkBuddy、Qoder、Trae 仍用专用连接器；包内 ZCode 渠道不单独使用
    "dsh-llm-retry-settings" # LLM 重试次数和错误码
    "@michengai/dsh-pua" # 验收循环和失败换方法，语气可关
    "dsh-soul" # 人设和回复风格，不是记忆
    "dsh-memory-palace" # 本地 Markdown 长期记忆。比 Mem0 更能直接改，不叠第二份召回
    "dsh-connect-workbuddy" # 本机登录的 WorkBuddy 模型。npm 上的 dsh-workbuddy 没有 bundle
    "@dmh2002/dsh-connect-qoder" # 本机 Qoder PAT。无 scope 的 dsh-connect-qoder 停在 0.2
    "dsh-connect-trae" # 本机登录的 Trae 模型
    "dsh-codex-connect" # ChatGPT 登录后的 Codex 模型
    "@sputnikzaychik/dsh-qq-bot" # QQ 会话接到 DSH。人设留空则不注入
    "@ggboy123/dsh-paper-reader" # 论文 PDF 伴读
    "dsh-paper-translator" # 论文 HTML 翻译，保留公式
    "dsh-paperdesk" # 论文文库和精读笔记
    "dsh-paper-insight" # 论文到产品、沙箱和 PRD。检索和精读仍用已留的论文插件
    "dsh-cite" # DOI 和 BibTeX 引文工作台
    "dsh-plugin-zotero" # 操作本机 Zotero 并读论文
    "@fffangchenghao/dsh-latex-look" # 编译 LaTeX 并对照版面
    "dsh-thesis" # 学位论文九阶段、学校模板、Word 和答辩
    "academic-research-skills-dsh" # 研究技能命令
    "dsh-aha-tutor" # 课程辅导
    "dsh-study-coach" # 课程地图和每日任务
    "dsh-ai4scholar" # 学术检索和写作工具
    "dsh-slides" # 提纲转幻灯
  ];
  orion.shortcuts.profile = "current";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-bak";
  home-manager.extraSpecialArgs = { inherit inputs hostName; };
  home-manager.users.jimmywang0417 = import ../../home/jimmy.nix;

  assertions = [
    {
      assertion = hostName == config.networking.hostName;
      message = "flake hostName and hosts/orion networking.hostName diverged";
    }
    {
      assertion = config.services.displayManager.defaultSession == "plasmax11";
      message = "Orion's default session is Plasma X11 (plasmax11) for ToDesk";
    }
    {
      assertion = config.services.displayManager.sddm.wayland.enable == false;
      message = "SDDM greeter stays on X11; Wayland remains a login choice";
    }
  ];
}
