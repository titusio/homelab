{
  config,
  lib,
  ...
}: let
  cfg = config.vps.openssh;
in {
  options.vps.openssh.enable = lib.mkEnableOption "VPS OpenSSH";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "prohibit-password";
      # we proxy 22 to the cluster because forgejo needs it.
      ports = [20022];
    };

    networking.firewall.allowedTCPPorts = [20022];
  };
}
