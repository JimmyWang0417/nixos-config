{ pkgs, ... }:
with pkgs; [
  btrfs-progs
  compsize
  ntfs3g
  exfatprogs
  dosfstools
  e2fsprogs
  xfsprogs
  cryptsetup
  lvm2
  mdadm
  mariadb
  nfs-utils
  samba
]
