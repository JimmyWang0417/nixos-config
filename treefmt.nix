{ lib, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    ruff-format.enable = true;
  };

  # Format maintained source, not imported desktop preferences, audit snapshots,
  # encrypted archives, or editor/plugin assets copied from the existing host.
  settings.formatter = {
    shfmt.includes = lib.mkForce [
      "bootstrap/*.sh"
      "tests/*.sh"
    ];
    ruff-format.includes = lib.mkForce [
      "lib/*.py"
      "scripts/*.py"
      "tests/*.py"
      "modules/**/*.py"
    ];
  };
  settings.global.excludes = [
    "secrets/**"
    "inventory/**"
    "home/assets/**"
    "home/nvim/**"
    "home/plasma/**"
    "home/ranger/**"
    ".direnv/**"
    ".pre-commit-config.yaml"
  ];
}
