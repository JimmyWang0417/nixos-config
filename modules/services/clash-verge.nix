{ config, ... }: {
  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    group = config.users.users.jimmywang0417.group;
  };
}
