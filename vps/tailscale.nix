{config, ...}: let
  authSecret = "tailscale/auth";
in {
  sops.secrets.${authSecret} = {};
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.${authSecret}.path;
  };
}
