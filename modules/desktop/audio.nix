{ pkgs, ... }: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Opt in per JACK application with pw-jack instead of a global library path.
    jack.enable = false;
    wireplumber.enable = true;
  };
  security.rtkit.enable = true;
  environment.systemPackages = [ pkgs.pipewire.jack ];
}
