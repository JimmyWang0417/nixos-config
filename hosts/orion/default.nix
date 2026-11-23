{
  config,
  lib,
  pkgs,
  inputs,
  hostName,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];

  networking.hostName = "Orion-Laptop";
  system.stateVersion = "26.05";

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

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
  orion.archives.ark.enable = true;
  orion.programs.ccSwitch = {
    enable = true;
    package = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.cc-switch-no-quick-panel;
  };
  orion.programs.claudeCage.enable = true;
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
      assertion = config.services.displayManager.defaultSession == "plasma";
      message = "Orion's default session is Plasma Wayland (plasma)";
    }
    {
      assertion = lib.all (name: lib.elem name config.services.displayManager.sessionData.sessionNames) [
        "plasma"
        "xfce"
      ];
      message = "Orion requires Plasma Wayland and the selectable Xfce X11 session for ToDesk";
    }
    {
      assertion =
        config.services.xserver.desktopManager.xfce.enable
        && !config.services.xserver.desktopManager.xfce.enableWaylandSession;
      message = "The ToDesk fallback is Xfce X11";
    }
    {
      assertion = config.services.displayManager.sddm.wayland.enable == false;
      message = "SDDM greeter stays on X11 while the default desktop uses Wayland";
    }
  ];
}
