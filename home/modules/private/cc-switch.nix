{
  secret = "cc-switch";
  destination = ".cc-switch";
  flat = true;
  files = [ "cc-switch.db" ];
  guards = [ "cc-switch.db" "cc-switch.db-wal" "cc-switch.db-shm" ];
}
