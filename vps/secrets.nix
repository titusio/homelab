{
  config,
  lib,
  ...
}: let
  cfg = config.vps.secrets;
in {
  options.vps.secrets = {
    enable = lib.mkEnableOption "VPS sops secrets";
    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the host's sops-encrypted secrets file";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = cfg.sopsFile;
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
