# Community development and maintenance tools

The user approves nh, direnv/nix-direnv, nix-index-database/comma, and formatting,
static checks and CI. Backups are explicitly postponed and documented as a candidate.

Use independent Home Manager development modules. nh selects the writable checkout
and explicit #orion output; native Nix GC remains the automatic cleanup policy.
direnv integrates with Zsh and caches per-project devShells without globally
trusting project code. The pinned index provides wrappers and command-not-found
integration; pay-respects retains explicit correction without overriding that hook.
The index is not guaranteed to match the nixpkgs snapshot exactly.

Add treefmt-nix and git-hooks.nix following the same unstable package set. Format
maintained Nix, Python and shell sources while excluding imported desktop assets,
audit snapshots and encrypted archives. Use statix/deadnix and actionlint checks.
Exclude only intentional module style rules from statix. Expose formatter/checks
through flake outputs and hooks through the devShell. CI runs built checks and
existing configuration/behavior tests without secrets or a full system build.
Pin actions to verified upstream commits.

Verify evaluated wiring, actual read-only manager CLI behavior, built checks and
the existing suite. Do not activate NixOS, trust direnv projects, collect garbage
or install real-host Git hooks during validation.
