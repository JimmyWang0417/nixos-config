{ lib, pkgs, ... }:
let seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in {
  home.packages = [ pkgs.nerd-fonts.hack ];
  # Register profile-installed fonts without adding another CJK fallback chain.
  fonts.fontconfig.enable = true;
  home.activation.konsolePreferences = seed {
    ".config/konsolerc" = ../../assets/apps/konsolerc;
    ".local/share/konsole/orion.profile" = ../../assets/apps/konsole.profile;
    ".local/share/konsole/Breath.colorscheme" = ../../assets/apps/Breath.colorscheme;
  };
}
