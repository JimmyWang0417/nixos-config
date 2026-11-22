# Orion: stable interface, unstable software

The user requested a complete software freshness review and migration to 26.11
plus unstable if warranted. On 2026-11-22, `nixos-26.11` and Home Manager
`release-26.11` returned HTTP 404. The user selected the current 26.11pre rolling
system, then clarified: retain stable only as an input and explicit interface;
all installed software must come from unstable. Parallel audit work was authorized.

## Decision

Retain the input named `nixpkgs` at `nixos-26.05` until the official 26.11
branch exists. Expose its packages lazily as `pkgsStable`; existing modules do
not request that argument. Use `nixpkgs-unstable` tracking `nixos-unstable` for
NixOS modules, the global `pkgs`, Home Manager, drivers, fonts and the dev shell.
Home Manager master, hardware, sops, NUR and the custom package repository follow
that same unstable input. Keep overlays and unfree policy in the global set;
remove redundant independent imports in application modules.

Using one package set avoids mixing stable desktop libraries with newer plugins
and services. The `nixos-unstable` branch has NixOS channel test coverage but may
trail `nixpkgs-unstable` and upstream application releases. Unstable is a package
repository policy, not a promise that every application is the newest upstream
release. Custom NUR packages remain custom packages built against unstable.

## Constraints and validation

- Preserve `system.stateVersion` and `home.stateVersion` at `26.05`; these are
  compatibility defaults, not the selected release.
- Plasma 6.8 removed X11. The user approved Plasma Wayland as default plus
  Xfce X11 for ToDesk. Preserve SDDM X11, PRIME offload, Linux 6.12 and secrets.
- The user additionally requested Xfce appearance matching the current system:
  adapt the existing WhiteSur wallpaper/decorations, Tela icons, light appearance,
  two-panel layout and fonts to Xfce without changing Plasma appearance.
- The running host is Manjaro. Do not install, activate, repartition, modify boot
  entries or reboot.
- Evaluate the full system derivation and existing flake checks. Add source
  policy validation to prevent silent use of stable packages.
- Inventory every configured package and explicitly selected bundled component,
  including fonts, editor extensions and runtime-managed plugin declarations.
  Deduplicate repeated entries; distinguish upstream stable, preview, deliberate
  old versions and upstream versions not independently verified.
- Compare before/after versions and give authoritative upstream links where
  verified. Do not count unverified rows as current.
- Evaluation does not prove complete builds or hardware runtime behavior.

## Future 26.11 transition

After verifying availability, change only the retained stable input to
`nixos-26.11` and update its lock. Keep runtime packages and modules on unstable
under the user's final policy. Moving runtime back to release modules would be
a separate policy change.

## Expanded user requirements

The user explicitly requested finer module granularity across the repository,
separate DSH configuration, complete Chinese input handling, verification and
completion of VS Code/extension settings and other actual on-host application
preferences, then committing and uploading all finished work.

System modules now group by core, hardware, desktop, networking, services, pure
package catalog and program behavior. Host UUIDs/PCI IDs stay in hosts/orion.
Home Manager keeps a thin identity/composition entrypoint with independent
editor, shell, desktop/Xfce and per-application modules. DSH plugin domains and
reconciliation logic remain separate while retaining existing public options.

Public UI preferences are seeded only if absent. Existing application state is
not overwritten. Private tar archives are restored at runtime from sops using a
shared traversal/link-resistant helper, never decrypted into the repository or
Nix store. NetworkManager/WPS require root destinations; user application
archives remain under HOME. Preserve the existing user's licenses and history
without claiming that an older license necessarily activates a newer product.

Upload uses an ordinary fast-forward git push after validation; no force push
or runtime activation.
