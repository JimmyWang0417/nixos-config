# Desktop Cleanup Implementation Plan

**Goal:** Apply the three explicitly accepted cleanup items and repair a duplicate policy source.

**Architecture:** Keep existing feature modules. Cron and audio policy remain in
their focused modules; Neovim keeps Coc as its diagnostic and clangd integration.

## Scope and constraints

- Disable empty cron, retain logrotate and existing systemd timers.
- Remove only JACK's global library injection; provide the native pw-jack wrapper.
- Remove Syntastic and the manual clangd server entry, retaining the Coc extension.
- Keep all other audio capabilities and user-required applications.
- Do not stop current Manjaro services, purge indices, delete plugin checkouts or
  alter the user-requested stable toolchain activation.
- Make orion.nix.allowUnfree the single policy source; Orion still selects true.

## Verification and publication

- [x] Check native option wiring and actual pw-jack child environment.
- [x] Verify Neovim plugin declarations, config and language-server routing.
- [x] Run the full suite and built formatting/static checks; refresh audit metadata.

Publication: commit/push after verification and confirm the remote revision and CI.
