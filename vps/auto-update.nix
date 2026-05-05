{...}: {
  system.autoUpgrade = {
    enable = true;
    flake = "git+ssh://git@github.com/titusio/homelab#corellian";
    flags = [
    ];
    rebootWindow = {
      lower = "01:00";
      upper = "05:00";
    };
    dates = "04:00 UTC";
    randomizedDelaySec = "45min";
  };

  services.webhook = {
    enable = true;
    hooks = {
      nixos-rebuild = {
        execute-command = "/run/current-system/sw/bin/nixos-rebuild";
        pass-arguments-to-command = [
          {
            source = "string";
            name = "switch";
          }
          {
            source = "string";
            name = "--flake";
          }
          {
            source = "string";
            name = "git+ssh://git@github.com/titusio/homelab#corellian";
          }
        ];
      };
    };
  };
}
