{ pkgs }:
{
  animeko = pkgs.callPackage ./animeko { };
  botmux = pkgs.callPackage ./botmux { };
  crm = pkgs.callPackage ./crm { };
  easyconnect = pkgs.callPackage ./easyconnect { };
  grok-bot = pkgs.callPackage ./grok-bot { };
  xjtu-course-genius = pkgs.callPackage ./xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./xjtutoolbox { };
}
