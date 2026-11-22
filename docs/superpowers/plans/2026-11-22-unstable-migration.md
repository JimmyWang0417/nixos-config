# Orion Unstable Software Migration Implementation Plan

**Goal:** Retain stable as an opt-in source/interface while the complete system
and all configured software use one locked unstable package set.

**Architecture:** `nixpkgs` remains the retained stable source;
`nixpkgs-unstable` tracks `nixos-unstable` and supplies NixOS modules, packages,
Home Manager, drivers, NUR dependencies and the dev shell. `pkgsStable` is lazy
and unused by current modules.

**Tech Stack:** Nix flakes, NixOS, Home Manager, NUR.

## Global Constraints

- Preserve both stateVersion values at `26.05`.
- Use user-approved Plasma Wayland plus Xfce X11 fallback; preserve SDDM X11,
  ToDesk, PRIME offload and Linux 6.12.
- Style Xfce using the existing WhiteSur wallpaper, Tela icons and light two-panel layout.
- Do not activate NixOS or change the running Manjaro system.
- Preserve unrelated user files.
- Audit all declared software; explicitly mark upstream checks without proof.

## Tasks

- [x] Record baseline software versions, official branch availability and
  upstream releases; run baseline flake check.
- [x] Implement retained stable source and `pkgsStable` interface in `flake.nix`;
  use unstable for runtime, input follows and dev shell.
- [x] Replace redundant independent unstable imports with global `pkgs` in
  `modules/packages.nix`, `home/editors.nix` and `home/jimmy.nix`.
- [x] Run `nix flake update home-manager nixpkgs-unstable` to regenerate locks.
- [x] Run `bash tests/eval.sh`, inspect assertions and package provenance. Fix
  demonstrated incompatibilities in the relevant modules and repeat checks.
- [x] Collect exhaustive system/home/font/extension/plugin inventory and compare
  baseline, migrated and independently verified upstream versions.
- [x] Update README, software documentation and a browsable version audit with
  measured improvements, remaining gaps and future stable-input upgrade steps.
- [x] Run `git diff --check`, review the final diff and report verification limits.

Execution continues in this chat. Parallel agents handle independent upstream
checks and source-policy verification; the main agent integrates and evaluates.

- [x] Configure Xfce appearance in `home/xfce.nix`, preserving existing Plasma settings;
  verify theme assets, panel settings and the complete system again.

## Additional authorized work

- [x] Split system and Home Manager concerns at finer granularity; preserve host facts.
- [x] Extract DSH options/runtime and thirteen ordered plugin groups.
- [x] Audit actual editor settings and repair missing locale/HDL tool integration.
- [x] Migrate safe existing UI preferences and shell prompt; align proxy alias.
- [x] Complete Wayland/X11 input-method branches and private learned-dictionary initialization.
- [x] Complete private-archive restoration for user apps, NetworkManager and WPS.
- [x] Validate consolidated module graph, input/session behavior, private archive safety,
  theme assets and editor tools; refresh complete software/configuration audit.
Publication: perform an ordinary commit/push to origin and verify the remote revision;
the Git remote is the authoritative publication record.
