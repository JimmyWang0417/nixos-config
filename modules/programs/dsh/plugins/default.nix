# Keep group order explicit: activation passes this ordered list to dsh.
let
  groups = [
    ./core.nix
    ./context.nix
    ./workbench.nix
    ./interaction.nix
    ./models.nix
    ./behavior.nix
    ./connectors.nix
    ./chat.nix
    ./reading.nix
    ./bibliography.nix
    ./writing.nix
    ./learning.nix
    ./slides.nix
  ];
in
builtins.concatLists (map import groups)
