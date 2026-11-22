{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.orion.archives.ark;
in
{
  options.orion.archives.ark = {
    enable = lib.mkEnableOption "Ark with explicitly supplied archive backends";
    legacyChineseZip = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Try strict GB18030 for unlabelled legacy ZIP filenames in Ark's private libzip; disable for ambiguous non-Chinese legacy archives.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = import ../../packages/ark {
        inherit pkgs;
        inherit (cfg) legacyChineseZip;
      };
      description = "Ark and its archive backends, all built from the global package set.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    # Clear inherited disabled-plugin lists; availability still depends on the
    # executable/library checks performed by each upstream Ark plugin.
    environment.etc."xdg/arkrc".text = ''
      [Plugins]
      disabledPlugins[$i]=
    '';
  };
}
