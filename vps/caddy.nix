{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.vps.caddy;
  authSecret = "caddy/hetzner";
in {
  options.vps.caddy = {
    enable = lib.mkEnableOption "Caddy Proxy";
    hetzner.enable = lib.mkEnableOption ''
      the Hetzner DNS plugin, required for DNS-01 challenges. Only needed for
      hosts that serve domains hosted at Hetzner which can't use HTTP-01
      (wildcards, internal-only names). Pulling this in rebuilds Caddy from
      source and requires the ${authSecret} secret in the host's sops file
    '';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.caddy.enable = true;
    }

    (lib.mkIf cfg.hetzner.enable {
      sops.secrets.${authSecret} = {};
      sops.templates."caddy.env".content = ''
        HZTOKEN=${config.sops.placeholder.${authSecret}}
      '';
      services.caddy = {
        environmentFile = config.sops.templates."caddy.env".path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/caddy-dns/hetzner/v2@v2.0.0"
          ];
          hash = "sha256-EseUjOQ2wIvI/sHbP5pCFyTLKgfI989i44Mwe0qCikI=";
        };
      };
    })
  ]);
}
