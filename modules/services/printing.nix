{ ... }: {
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Skanlite is installed. Logged-in seats get the scanner through uaccess;
  # jimmywang0417 is also in the scanner group.
  hardware.sane.enable = true;

}
