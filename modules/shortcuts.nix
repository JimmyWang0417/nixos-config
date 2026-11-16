# Two shortcut profiles. The host picks one with orion.shortcuts.profile.
# current: install the scanned kglobalshortcutsrc and do not start keyd.
# macos: keep that same file, and add a Super-as-Command layer.
#
# Skipped as ambiguous, so they are not in the macOS table:
# - bare Ctrl is never remapped
# - console keymap is unchanged
# - Command+Left/Right as line home/end (Left/Right are word jumps instead)
# - selection chords such as Command+Shift+arrows
{
  config,
  lib,
  ...
}:
let
  cfg = config.orion.shortcuts;
  # Live kglobalshortcutsrc does not override KRunner or Spectacle.
  # KRunner's desktop file is Alt+Space. Spectacle's defaults are
  # Shift+Print for the whole desktop and Meta+Shift+Print for a region.
  # Walk Through Windows already includes Meta+Tab.
  macosLayer = {
    c = "C-c";
    v = "C-v";
    x = "C-x";
    z = "C-z";
    "S-z" = "C-S-z";
    a = "C-a";
    s = "C-s";
    f = "C-f";
    p = "C-p";
    n = "C-n";
    t = "C-t";
    w = "C-w";
    q = "C-q";
    h = "C-h";
    m = "C-m";
    space = "A-space";
    tab = "M-tab";
    comma = "C-comma";
    "S-3" = "S-print";
    "S-4" = "M-S-print";
    left = "A-left";
    right = "A-right";
    up = "C-home";
    down = "C-end";
  };
in
{
  options.orion.shortcuts.profile = lib.mkOption {
    type = lib.types.enum [
      "current"
      "macos"
    ];
    default = "current";
    description = ''
      current keeps the migrated KDE shortcuts and leaves keyd off.
      macos keeps those shortcuts and maps Super to Command with keyd.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.profile == "current") {
      home-manager.users.jimmywang0417.imports = [
        ({ lib, pkgs, ... }: {
          home.activation.currentShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.coreutils}/bin/install -Dm644 ${./kglobalshortcutsrc-current} "$HOME/.config/kglobalshortcutsrc"
            ${pkgs.coreutils}/bin/chmod u+w "$HOME/.config/kglobalshortcutsrc"
          '';
        })
      ];
    })
    (lib.mkIf (cfg.profile == "macos") {
      services.keyd = {
        enable = true;
        keyboards.default = {
          ids = [ "*" ];
          settings = {
            main = {
              leftmeta = "overload(command, leftmeta)";
              rightmeta = "overload(command, rightmeta)";
            };
            command = macosLayer;
          };
        };
      };
    })
  ];
}
