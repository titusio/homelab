{
  config,
  lib,
  ...
}: let
  cfg = config.vps.secrets;
in {
  options.vps.secrets.enable = lib.mkEnableOption "VPS sops secrets";

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../secrets/corellian.enc.yaml;
      age.keyFile = "/root/.config/sops/age/keys.txt";

      secrets = {
        "git/sshKey" = {
          path = "/root/.ssh/id_ed25519";
          mode = "0600";
        };
      };
    };
  };
}
