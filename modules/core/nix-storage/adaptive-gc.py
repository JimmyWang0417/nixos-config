#!/usr/bin/env python3
"""Generate native build-time Nix GC watermarks from actual filesystem capacity."""

import argparse
import os
from pathlib import Path
import tempfile

GIB = 1024**3


def thresholds(capacity):
    if capacity < 100:
        raise ValueError("Filesystem capacity must be at least 100 bytes")
    # Percentage watermarks, bounded for ordinary disks and capped for tiny ones.
    low = min(capacity // 10, max(2 * GIB, min(capacity * 5 // 100, 16 * GIB)))
    high = min(capacity // 5, max(4 * GIB, min(capacity * 10 // 100, 32 * GIB)))
    return low, high


def write_config(store, output):
    stats = os.statvfs(store)
    capacity = stats.f_blocks * stats.f_frsize
    low, high = thresholds(capacity)
    content = (
        f"# Generated from {store}: capacity={capacity} bytes\n"
        f"min-free = {low}\nmax-free = {high}\n"
    )
    # The daemon's RuntimeDirectory exists before ExecStartPre is invoked.
    # Atomic replacement also lets client processes read a complete config.
    output = Path(output)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=output.parent, prefix=".settings-", delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
            stream.flush()
            os.fchmod(stream.fileno(), 0o644)
            os.fsync(stream.fileno())
        os.replace(temporary, output)
        temporary = None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(
        f"Adaptive Nix GC: capacity={capacity}, min-free={low}, max-free={high}",
        flush=True,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--store", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    write_config(args.store, args.output)


if __name__ == "__main__":
    main()
