{ pkgs, ... }:
let
  # Small text file. remote-add reads it from the store, then still has to
  # reach Flathub for the summary. The oneshot retries; it does not sit in
  # front of SDDM.
  flathubRepo = pkgs.fetchurl {
    url = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    hash = "sha256-M3HdJQ5h2eFjNjAHP+/aFTzUQm9y9K+gwzc64uj+oDo=";
  };
in {
  # Flathub is the system remote on this laptop. No Flatpak apps are installed.
  services.flatpak.enable = true;
  systemd.services.flatpak-flathub = {
    description = "Register the Flathub system remote";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 600;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 20;
      Restart = "on-failure";
      RestartSec = 60;
    };
    script = ''
      if ${pkgs.flatpak}/bin/flatpak remote-list --system --columns=name | ${pkgs.gnugrep}/bin/grep -qx flathub; then
        exit 0
      fi
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub ${flathubRepo}
    '';
  };

}
