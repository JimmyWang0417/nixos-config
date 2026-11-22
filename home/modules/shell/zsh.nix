{ lib, pkgs, osConfig, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      ls = "lsd";
      pon = "export http_proxy=${osConfig.orion.nix.proxy} https_proxy=${osConfig.orion.nix.proxy} HTTP_PROXY=${osConfig.orion.nix.proxy} HTTPS_PROXY=${osConfig.orion.nix.proxy}";
      poff = "unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY";
    };
    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${../../assets/shell/p10k.zsh}
      eval "$(${pkgs.pay-respects}/bin/pay-respects zsh)"
    '';
  };

  home.packages = with pkgs; [ lsd pay-respects zsh-powerlevel10k ];
}
