# Adaptive Nix storage maintenance

The user accepts storage maintenance and requests adaptive free-space thresholds.
Implement only that storage scope; the separate community-tool suggestions remain
recommendations.

Use native Nix build-time GC with byte thresholds generated before each daemon
start from statvfs of the actual /nix/store filesystem. Compute low/high watermarks
as 5%/10% of capacity, bounded to 2–16 / 4–32 GiB respectively. On tiny filesystems,
cap these at 10%/20% of capacity. This keeps a gap between trigger and target and
avoids excessive reservations on small disks. These values are project policy,
not official recommended constants. No evaluation-time disk access or periodic
daemon restart. Resizing becomes effective on the next daemon start.

Generate a mode-0644 runtime include atomically inside the daemon-owned runtime
directory. Missing optional include must not break builds/checks on another host.
Generation errors stop daemon startup visibly. Native GC never deletes generations
or manually removes GC roots; it may fail to reach the target if roots retain data.
Capacity is filesystem capacity, not Btrfs qgroup or thin-pool physical headroom.

Split storage maintenance into age-based GC, adaptive GC, and scheduled optimisation
modules. Preserve weekly 30-day history cleanup and the existing 20-entry GRUB
menu. Add persistent weekly store optimisation on AC power using upstream defaults.

Verify arithmetic across tiny/normal/large disks and invariant low < high < total;
test actual statvfs and atomic file output in temporary directories, native Nix
include parsing, evaluated unit wiring, and the existing configuration suite.
Never activate services or collect garbage on the running Manjaro host.
