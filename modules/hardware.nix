# Filesystems taken from findmnt, lsblk, and /etc/fstab on 2026-11-16.
# This module only names existing filesystems. It does not partition or format.
#
# nvme0 SK hynix PC801 512G is the Windows disk. Do not format it.
#   nvme0n1p1 vfat  UUID=0AF1-1155           label SYSTEM, mounted at /boot/efi
#   nvme0n1p2       16M Microsoft reserved, no filesystem
#   nvme0n1p3 ntfs  UUID=E88024F38024C9C0    label Windows, not in fstab
#   nvme0n1p4 ntfs  UUID=24AC6033AC5FFE24    not in fstab
# nvme1 WD_BLACK SN7100 2TB
#   nvme1n1p1 ntfs  UUID=CA1CDD311CDD18F1    label 数据分区, not in fstab
#   nvme1n1p2 btrfs UUID=fd32207f-8a11-48d7-9d04-9316cdb8c265
#     subvol=@      /
#     subvol=@home  /home
#     subvol=@cache /var/cache
#     subvol=@log   /var/log
#
# Swap is not configured. fstab's /swapfile line is commented out, swapon is
# empty, and no swapfile is present on the mounted subvolumes. The running
# kernel still has resume=UUID=fd32207f-8a11-48d7-9d04-9316cdb8c265 and
# resume_offset=90187008 (/sys/power/resume is 259:7, which is nvme1n1p2).
# /etc/openswap.conf is an unused template whose swap UUID is not a disk on
# this machine. Those resume parameters are intentionally not copied.
{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.firmware = [
    pkgs.sof-firmware
    pkgs.alsa-firmware
  ];

  boot.supportedFilesystems = [
    "btrfs"
    "ntfs"
    "exfat"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd:1"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [
      "subvol=@cache"
      "compress=zstd:1"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/fd32207f-8a11-48d7-9d04-9316cdb8c265";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "compress=zstd:1"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ];
  };

  # Shared Windows ESP on nvme0n1p1. Mount only; never format.
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/0AF1-1155";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
      "utf8"
    ];
  };

  swapDevices = [ ];
}
