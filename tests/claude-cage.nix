{ pkgs, cage }:
pkgs.runCommand "claude-cage-runtime-checks"
  {
    nativeBuildInputs = [
      pkgs.binutils
      pkgs.gnugrep
    ];
  }
  ''
    set -euo pipefail
    mkdir -p "$out"
    ${cage}/bin/claude-cage version | tee "$out/version.txt"
    grep -F '0.1.8' "$out/version.txt"
    ${cage}/bin/claude-cage verify-web-assets > "$out/web-assets.txt"
    ${cage}/bin/cage-desktop --version | grep -F '0.1.8'
    ${cage}/bin/cage-desktop --self-test | tee "$out/desktop-policy.txt"
    ${cage}/lib/claude-cage/mihomo -v | grep -F 'v${cage.bundledMihomoVersion}'
    ${cage.runtime.qemu}/bin/qemu-system-x86_64 --version > "$out/qemu.txt"
    ${cage.runtime.qemu}/bin/qemu-img --version > "$out/qemu-img.txt"
    test -s ${cage.runtime.qemu}/share/qemu/edk2-x86_64-code.fd
    ${pkgs.stdenv.cc.bintools.dynamicLinker} --list \
      ${cage}/lib/claude-cage/.cage-desktop-wrapped > "$out/desktop-libraries.txt"
    if grep -F 'not found' "$out/desktop-libraries.txt"; then
      exit 1
    fi
    grep -F '${pkgs.glibc}/lib/libc.so.6' "$out/desktop-libraries.txt"
    # Read-only commands above must not create or initialize a user profile/VM.
    test ! -e "$HOME/.claude-cage"
  ''
