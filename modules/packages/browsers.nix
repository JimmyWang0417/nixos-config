{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
    # Mozilla policy DisableAppUpdate. Stops Firefox checking for a new
    # version and showing its update UI. https://firefox-admin-docs.mozilla.org/reference/policies/disableappupdate/
    policies.DisableAppUpdate = true;
  };

  # Plasma sets enablePlasmaBrowserIntegration. The host JSON is installed
  # only once programs.chromium.enable is true. That module covers Chromium
  # and Chrome. Edge reads the same manifest from its own directory.
  programs.chromium.enable = true;
  environment.etc."opt/edge/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
    "${pkgs.kdePackages.plasma-browser-integration}/etc/opt/chrome/native-messaging-hosts/org.kde.plasma.browser_integration.json";

}
