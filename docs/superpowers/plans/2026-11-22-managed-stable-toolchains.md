# Managed Stable Toolchains

**Goal:** Install elan/rustup from unstable and declare stable defaults whose
actual installation and writable settings are reconciled by Home Manager.

**Design:** Separate Lean and Rust modules under home/modules/development.
Install Lean before setting elan's stable default; rustup installs stable when
selecting it, then installs formatter/lint/source components. Remove competing
pinned Rust commands from the VS Code profile. Respect project-local toolchain files. Use independent XDG data roots for NixOS-patched downloads; preserve legacy directories (both observed directory-override tables were empty).

- [x] Inspect the locked package sources and manager default command behavior.
- [x] Add two independent modules and the explicit stable policy composition.
- [x] Verify actual activation command ordering, dry-run/failure behavior,
  manager CLIs and the full configuration; update metadata/documentation.
Publication: commit/push after verification and confirm the remote head; the Git remote is the publication record.
