{ pkgs, ... }:
with pkgs;
[
  vlc
  obs-studio
  alsa-utils
  ffmpeg
  libdvdcss
  mesa-demos
  gst_all_1.gstreamer
  gst_all_1.gst-plugins-base
  gst_all_1.gst-plugins-good
  gst_all_1.gst-plugins-bad
  gst_all_1.gst-plugins-ugly
  gst_all_1.gst-libav
]
