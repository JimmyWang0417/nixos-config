{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "crm";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "wtklbm";
    repo = "crm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OwDBDNTb4s0Rb9yXef9sWYBi9W/+Rg/ZpRtqqPeg8L0=";
  };

  # Tag v0.2.2 has no Cargo.lock. pkgs/crm/Cargo.lock is produced by
  # `cargo generate-lockfile` on that tag and is what importCargoLock reads.
  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Cargo registry manager";
    homepage = "https://github.com/wtklbm/crm";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "crm";
  };
})
