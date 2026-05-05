{lib, ...}: {
  systemd.services.nixos-rebuild-webhook = {
    description = "NixOS rebuild triggered by webhook";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/nixos-rebuild switch --flake git+ssh://git@github.com/titusio/homelab#corellian";
      Environment = "HOME=/root PATH=/run/current-system/sw/bin";
    };
  };

  security.sudo.extraRules = [{
    users = ["webhook"];
    commands = [{
      command = "/run/current-system/sw/bin/systemctl start nixos-rebuild-webhook";
      options = ["NOPASSWD"];
    }];
  }];

  services.webhook = {
    enable = true;
    hooks = {
      nixos-rebuild = {
        execute-command = "/run/current-system/sw/bin/sudo";
        pass-arguments-to-command = [
          { source = "string"; name = "systemctl"; }
          { source = "string"; name = "start"; }
          { source = "string"; name = "nixos-rebuild-webhook"; }
        ];
      };
    };
  };

  systemd.services.webhook.serviceConfig = {
    Environment = lib.mkForce "PATH=/run/current-system/sw/bin";
  };
}
