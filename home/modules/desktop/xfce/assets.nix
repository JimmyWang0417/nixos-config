{ pkgs, inputs, ... }:
let
  nurPkgs = inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system};
  wallpaper = "${nurPkgs.whitesur-kde}/share/wallpapers/WhiteSur/contents/images/3840x2160.jpg";
  # Light WhiteSur matches the existing Aurorae decoration; green is the
  # closest packaged accent to the current Breath selection color (53,191,164).
  theme = pkgs.whitesur-gtk-theme.override {
    colorVariants = [ "light" ];
    themeVariants = [ "green" ];
    opacityVariants = [ "solid" ];
  };
  themeName = "WhiteSur-Light-solid-green";
in
{
  inherit wallpaper theme themeName;
}
