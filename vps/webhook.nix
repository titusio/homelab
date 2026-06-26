{
  config,
  lib,
  ...
}: let
  cfg = config.vps.webhook;
in {
  options.vps.webhook.enable = lib.mkEnableOption "NixOS rebuild webhook";

  config = lib.mkIf cfg.enable {
    systemd.services.nixos-rebuild-webhook = {
      description = "NixOS rebuild triggered by webhook";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/nixos-rebuild switch --flake git+ssh://git@github.com/titusio/homelab#${config.vps.nixosFlakeHost} --refresh";
        Environment = "HOME=/root PATH=/run/current-system/sw/bin";
      };
    };

    security.sudo.extraRules = [
      {
        users = ["webhook"];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl start nixos-rebuild-webhook.service";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    services.webhook = {
      enable = true;
      hooks = {
        nixos-rebuild = {
          execute-command = "/run/wrappers/bin/sudo";
          pass-arguments-to-command = [
            {
              source = "string";
              name = "/run/current-system/sw/bin/systemctl";
            }
            {
              source = "string";
              name = "start";
            }
            {
              source = "string";
              name = "nixos-rebuild-webhook.service";
            }
          ];
        };
      };
    };

    systemd.services.webhook.serviceConfig = {
      Environment = lib.mkForce "PATH=/run/current-system/sw/bin";
    };
  };
}
