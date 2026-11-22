# Ark Chinese ZIP Implementation Plan

**Goal:** Correct legacy Chinese ZIP filenames in Ark and supply working backends.

**Architecture:** An Ark-specific package uses a private patched libzip from the
same unstable snapshot. NixOS module options select the package and fallback policy.

## Tasks

- [x] Reproduce the issue and inspect exact upstream settings/backends.
- [x] Disable Flatpak support and remove Flathub registration.
- [x] Implement a narrowly scoped codec fallback and package backends.
- [x] Verify real Ark extraction, name lookup and plugin loading in isolation.
- [x] Integrate built checks, refresh metadata, document limitations and run checks.

Publication: commit/push after verification and confirm the remote revision and CI.
