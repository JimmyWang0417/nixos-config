{ config, lib, pkgs, ... }:
let
  cfg = config.orion.fonts.windows;
in
{
  options.orion.fonts.windows = {
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      example = lib.literalExpression "pkgs.nur.repos.chillcicada.ttf-ms-win10";
      description = "Windows 字体包，加入系统字体；null 时不额外安装字体包。";
    };
    enable = lib.mkEnableOption "fonts copied from a local directory";
    directory = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.jimmywang0417.home + "/.local/share/fonts/windows";
      description = "把你自己的字体放进这个目录再打开开关。";
    };
  };

  # The directory is outside the flake. Touch it only when the switch is on,
  # so a missing or empty directory does not fail evaluation while enable is false.
  config = lib.mkMerge [
    { fonts.packages = lib.optional (cfg.package != null) cfg.package; }
    (lib.mkIf cfg.enable (
      let
        dir = lib.removeSuffix "/" cfg.directory;
        dirExists = builtins.pathExists dir;
        isFontName = name:
          lib.any (suffix: lib.hasSuffix suffix (lib.toLower name)) [ ".ttf" ".otf" ];
        fontNames =
          if dirExists then
            lib.filter isFontName (builtins.attrNames (builtins.readDir dir))
          else
            [ ];
        fontsSrc =
          if fontNames == [ ] then
            null
          else
            lib.cleanSourceWith {
              name = "windows-fonts-src";
              src = /. + dir;
              filter = path: type:
                (type == "directory" && baseNameOf path == baseNameOf dir)
                || (type != "directory" && isFontName (baseNameOf path));
            };
        windowsFonts = pkgs.runCommand "windows-fonts" { } ''
          mkdir -p "$out/share/fonts/truetype" "$out/share/fonts/opentype"
          shopt -s nullglob
          src=${lib.escapeShellArg fontsSrc}
          for f in "$src"/*.[Tt][Tt][Ff]; do
            cp -L -- "$f" "$out/share/fonts/truetype/"
          done
          for f in "$src"/*.[Oo][Tt][Ff]; do
            cp -L -- "$f" "$out/share/fonts/opentype/"
          done
        '';
      in
      {
        warnings = lib.optional (dirExists && fontNames == [ ])
          "orion.fonts.windows.directory has no .ttf or .otf files (${dir}). 把你自己的字体放进这个目录再打开开关。";

        assertions = [
          {
            assertion = lib.hasPrefix "/" dir;
            message = "orion.fonts.windows.directory must be an absolute path.";
          }
          {
            assertion = dirExists;
            message = "orion.fonts.windows.enable is true, but ${dir} is not visible. 把你自己的字体放进这个目录再打开开关。Pure flake evaluation hides this path; pass --impure.";
          }
        ];

        fonts.packages = lib.optional (fontsSrc != null) windowsFonts;
      }
    ))
  ];
}
