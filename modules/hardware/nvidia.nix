# Live stack, from mhwd and the running kernel:
#   video-hybrid-intel-nvidia-prime + video-modesetting
#   i915 on 00:02.0 Iris Xe [8086:46a6]
#   nvidia open kernel module 615.71.09 on 01:00.0 RTX 3060 Mobile [10de:2520]
#   cmdline: nvidia_drm.modeset=1 nvidia_drm.fbdev=1
#   NVreg_DynamicPowerManagement=0x02
#   NVreg_PreserveVideoMemoryAllocations=1
#   nvidia-suspend / nvidia-hibernate / nvidia-resume enabled
# nixos-hardware's common-gpu-nvidia turns on PRIME offload. Bus IDs are local.
{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
    };
  };
}
