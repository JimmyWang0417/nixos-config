{ ... }:
{
  imports = [ ./elan.nix ./rust.nix ];

  # Manager binaries are locked by Nix; toolchain versions are managed at runtime.
  orion.development = {
    elan = { enable = true; defaultToolchain = "stable"; };
    rust = { enable = true; defaultToolchain = "stable"; };
  };
}
