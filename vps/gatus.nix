{
  config,
  lib,
  ...
}: let
  cfg = config.vps.gatus;
in {
  options.vps.gatus = {
    enable = lib.mkEnableOption "Gatus status monitor";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain to serve the Gatus dashboard on";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Gatus configuration (mapped directly to YAML)";
    };
    auth = {
      enable = lib.mkEnableOption "Pocket ID authentication";
      clientId = lib.mkOption {
        type = lib.types.str;
        description = "OAuth2 client ID registered in Pocket ID";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.gatus = {
      enable = true;
      settings = cfg.settings;
    };

    sops.secrets."gatus/oauth2ClientSecret" = lib.mkIf cfg.auth.enable {};
    sops.secrets."gatus/oauth2CookieSecret" = lib.mkIf cfg.auth.enable {};

    services.oauth2-proxy = lib.mkIf cfg.auth.enable {
      enable = true;
      provider = "oidc";
      clientID = cfg.auth.clientId;
      clientSecretFile = config.sops.secrets."gatus/oauth2ClientSecret".path;
      cookie.secretFile = config.sops.secrets."gatus/oauth2CookieSecret".path;
      oidcIssuerUrl = "https://id.titusio.net";
      email.domains = ["*"];
      upstream = ["http://localhost:8080"];
      reverseProxy = true;
      httpAddress = "127.0.0.1:4180";
    };

    services.caddy.enable = true;
    services.caddy.virtualHosts.${cfg.domain}.extraConfig =
      if cfg.auth.enable
      then ''
        reverse_proxy localhost:4180
      ''
      else ''
        reverse_proxy localhost:8080
      '';
  };
}
