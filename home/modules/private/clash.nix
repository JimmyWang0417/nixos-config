{
  secret = "clash-verge";
  destination = ".local/share/io.github.clash-verge-rev.clash-verge-rev";
  # Encryption key and profile index form one state set. Do not combine an
  # existing installation's key or profiles with archived credentials.
  guards = [ ".encryption_key" "profiles.yaml" "clash-verge.yaml" "profiles" ];
}
