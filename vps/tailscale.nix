{
  config,
  lib,
  ...
}: let
  cfg = config.vps.tailscale;
  authSecret = "tailscale/auth";
in {
  options.vps.tailscale.enable = lib.mkEnableOption "Tailscale VPN";

  config = lib.mkIf cfg.enable {
    sops.secrets.${authSecret} = {};
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.${authSecret}.path;
    };
  };
}
