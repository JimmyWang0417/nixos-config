{ ... }: {
  # Repository jobs use systemd timers; no system crontab is declared.
  services.cron.enable = false;
  services.logrotate.enable = true;
}
