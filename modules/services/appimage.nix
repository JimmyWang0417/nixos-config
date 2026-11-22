{ ... }: {
  # Run AppImages that are not Nix packages. animeko stays uninstalled.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

}
