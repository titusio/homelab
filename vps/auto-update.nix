{...}: {
  system.autoUpgrade = {
    enable = true;
    flake = "github:titusio/homelab#corellian";
    flags = [
      "--print-build-logs"
      "--commit-lock-file" # If you want to automatically commit the updated flake.lock
    ];
    rebootWindow = {
      lower = "01:00";
      upper = "05:00";
    };
    dates = "04:00 UTC";
    randomizedDelaySec = "45min";
  };
}
