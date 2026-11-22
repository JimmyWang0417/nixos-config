{ lib, pkgs, ... }:
let seed = import ../../lib/seed-config.nix { inherit lib pkgs; };
in {
  home.activation.discordPreferences = seed {
    ".config/discord/settings.json" = ../../assets/apps/discord.json;
  };
}
