{ config, lib, pkgs, ... }:
let
  cfg = config.orion.nvidia;
in
{
  options.orion.nvidia = {
    enable = lib.mkEnableOption "NVIDIA hybrid offload";
    open = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the open NVIDIA kernel module. Ampere and newer, including this RTX 3060 Mobile.";
    };
    finegrained = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set NVreg_DynamicPowerManagement=0x02 via hardware.nvidia.powerManagement.finegrained.";
    };
    intelBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "iGPU PCI id, such as PCI:0:2:0. The host sets this.";
    };
    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "dGPU PCI id, such as PCI:1:0:0. The host sets this.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.intelBusId != "" && cfg.nvidiaBusId != "";
        message = "orion.nvidia.enable needs intelBusId and nvidiaBusId from the host file.";
      }
    ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.intel-media-driver ];
      extraPackages32 = [ pkgs.pkgsi686Linux.intel-media-driver ];
    };

    hardware.nvidia = {
      open = cfg.open;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = cfg.finegrained;
      nvidiaSettings = true;
      prime = {
        offload.enable = true;
        intelBusId = cfg.intelBusId;
        nvidiaBusId = cfg.nvidiaBusId;
      };
    };

    environment.systemPackages = [ pkgs.nvidia-vaapi-driver ];
  };
}
