{ pkgs }:
{
  animeko = pkgs.callPackage ./animeko { };
  botmux = pkgs.callPackage ./botmux { };
  grub-theme-dedsec = pkgs.callPackage ./grub-theme-dedsec { };
  crm = pkgs.callPackage ./crm { };
  xjtu-course-genius = pkgs.callPackage ./xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./xjtutoolbox { };
}
