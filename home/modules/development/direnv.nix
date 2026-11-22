{ ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableGitIntegration = true;
    nix-direnv.enable = true;
    # No global whitelist: each project still requires `direnv allow`.
  };
}
