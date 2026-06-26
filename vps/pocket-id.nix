{
  config,
  lib,
  ...
}: let
  cfg = config.vps.pocketId;
in {
  options.vps.pocketId.enable = lib.mkEnableOption "Pocket ID OIDC provider";

  config = lib.mkIf cfg.enable {
    sops.secrets."pocket-id/encryptionKey" = {};
    sops.templates."pocket-id-environment".content = ''
      ENCRYPTION_KEY=${config.sops.placeholder."pocket-id/encryptionKey"}
    '';

    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://id.titusio.net";
        TRUST_PROXY = true;
      };
      environmentFile = config.sops.templates."pocket-id-environment".path;
      dataDir = "/var/lib/pocket-id";
    };

    services.caddy = {
      enable = true;
      virtualHosts."id.titusio.net".extraConfig = ''
        reverse_proxy http://localhost:1411
      '';
    };
  };
}
