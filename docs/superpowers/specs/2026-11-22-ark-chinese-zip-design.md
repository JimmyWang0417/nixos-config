# Ark legacy Chinese ZIP compatibility

The user requests correct Chinese ZIP filenames and working archive plugins, and
explicitly rejects Flatpak. Disable Flatpak support/Flathub registration without
removing unrelated NUR or AppImage applications.

Reproduced with actual locked Ark26.08.3: unflagged Windows/FAT GBK and GB18030
filenames become mojibake; ordinary UTF8 ZIP works. Ark has no upstream arkrc
default-encoding option. Native libzip uses CP437 for legacy names. Official Linux
7zz also ignores requested numeric codepages in its default forced-UTF8 conversion,
so a wrapper adding -mcp is not a sufficient fix.

Keep Ark's native ZIP plugin. Scope a libzip fallback patch to Ark only: preserve
ASCII, known/guessedUTF8, Unicode extra fields and raw accesses; in the CP437 fallback
branch, try strictGB18030 and otherwise keepCP437. Shared name lookup and extraction
must use the same conversion. Keep a Nix switch to disable the heuristic: unflagged
legacy byte strings are fundamentally ambiguous across encodings.

Supply executable backends on the actual Ark launch path while preserving its Qt
plugin setup. Declare native disabledPlugins policy explicitly to avoid old user
settings unexpectedly disabling shipped backends. Retain other Ark preferences.
Separate package/patch, NixOS integration and regression tests.

Verify actual offscreen Ark extraction, payload bytes, plugin loading, UTF8 markers,
unflaggedUTF8, Unicode-path extra fields, mixed names and CP437 fallback; verify
libzip name lookup for selected entries. Run the suite and built flake checks.
Do not alter realHOME files, start the current desktop, rewrite original archives
or uninstall current Manjaro applications during verification.
