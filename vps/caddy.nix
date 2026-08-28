{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.vps.caddy;
  authSecret = "caddy/hetzner";
in {
  options.vps.caddy.enable = lib.mkEnableOption "Caddy Proxy";

  config = lib.mkIf cfg.enable {
    sops.secrets.${authSecret} = {};
    sops.templates."caddy.env".content = ''
      HZTOKEN=${config.sops.placeholder.${authSecret}}
    '';
    services.caddy = {
      enable = true;
      environmentFile = config.sops.templates."caddy.env".path;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/hetzner/v2@v2.0.0"
        ];
        hash = "sha256-EseUjOQ2wIvI/sHbP5pCFyTLKgfI989i44Mwe0qCikI=";
      };
    };
  };
}
