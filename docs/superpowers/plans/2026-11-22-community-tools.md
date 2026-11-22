# Community Tools Implementation Plan

**Goal:** Implement the four approved developer/maintenance improvements.

**Architecture:** Separate Home Manager modules; one quality expression exposes
formatting, hooks, packages and built checks.

**Tech Stack:** Home Manager, nh, direnv, nix-index-database, treefmt-nix,
git-hooks.nix, GitHub Actions.

## Constraints

- All tools and input followers use nixpkgs-unstable.
- Preserve native 30-day cleanup and explicit stable Rust/Lean defaults.
- Do not automatically trust .envrc, enable a second cleanup job, or deploy backups.
- No system activation or real-host Git-hook installation during validation.

## Work

- [x] Add nh/direnv/index modules and explicit project opt-in documentation.
- [x] Resolve command-not-found collision and verify actual CLI output.
- [x] Lock new inputs to unstable followers and expose quality flake outputs.
- [x] Baseline-format maintained sources and run built lint/workflow checks.
- [x] Run evaluation/behavior suite and update current audit additions.
Publication: commit/push after verification; the Git remote records the published revision.
