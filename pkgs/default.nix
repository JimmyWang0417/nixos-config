{ pkgs }:
{
  animeko = pkgs.callPackage ./animeko { };
  botmux = pkgs.callPackage ./botmux { };
  crm = pkgs.callPackage ./crm { };
  easyconnect = pkgs.callPackage ./easyconnect { };
  xjtu-course-genius = pkgs.callPackage ./xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./xjtutoolbox { };
}
