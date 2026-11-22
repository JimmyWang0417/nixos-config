# Baidu's official libbrowserengine.so still requires the GTKmm 2.4 ABI.
# Build this one private compatibility library from upstream GNOME sources using
# the current caller's package set; never import an older nixpkgs collection.
{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  gtk2,
  glibmm_2_4,
  cairomm_1_0,
  pangomm_1_4,
  atkmm,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "gtkmm";
  version = "2.24.5";
  src = fetchurl {
    url = "mirror://gnome/sources/gtkmm/${lib.versions.majorMinor finalAttrs.version}/gtkmm-${finalAttrs.version}.tar.xz";
    hash = "sha256:0680a53b7bf90b4e4bf444d1d89e6df41c777e0bacc96e9c09fc4dd2f5fe6b72";
  };
  outputs = [
    "out"
    "dev"
  ];
  nativeBuildInputs = [ pkg-config ];
  propagatedBuildInputs = [
    glibmm_2_4
    gtk2
    atkmm
    cairomm_1_0
    pangomm_1_4
  ];
  doCheck = true;
  enableParallelBuilding = true;
  meta = {
    description = "Private GTKmm 2.4 ABI compatibility for the official Baidu Netdisk client";
    homepage = "https://gtkmm.org/";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
