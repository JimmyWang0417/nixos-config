# Adaptive Nix Storage Implementation Plan

**Goal:** Add filesystem-sized build-time GC thresholds and scheduled store deduplication.

**Architecture:** Focused modules under modules/core/nix-storage; a small Python
helper writes native Nix settings during daemon startup, before Nix reads them.

**Tech Stack:** NixOS modules, systemd, Python statvfs, native Nix GC.

## Global constraints

- User requested adaptive thresholds; do not hardcode a disk size.
- Retain weekly 30-day cleanup and the 20-entry boot menu.
- No runtime activation, repartitioning, root removal or garbage collection here.
- Leave the existing untracked nvim.log untouched.

## Work

- [x] Split existing GC into nix-storage/gc.nix and enable the storage composition.
- [x] Add adaptive-gc.py: capacity-based arithmetic and atomic native config writer.
- [x] Wire runtime include and daemon pre-start; add weekly upstream optimiser.
- [x] Exercise threshold boundaries, file output, evaluated wiring and Nix parsing.
- [x] Run tests/eval.sh and document runtime refresh and limitations.

Publication: commit/push after verification; the Git remote records the published revision.

The design specifies exact percentages, bounds, failure behavior and verification
scope in ../specs/2026-11-22-adaptive-nix-storage-design.md.
