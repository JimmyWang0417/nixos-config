{ pkgs, ... }: {
  # Applications are provided by Nix; keep Flatpak an explicit opt-in policy.
  services.flatpak.enable = false;
  # Plasma otherwise adds Discover for fwupd, including its Flatpak backend.
  # Firmware updates remain available through the fwupd service and fwupdmgr.
  environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];
}
