{
  config,
  lib,
  ...
}: let
  cfg = config.vps.proxy;
  domain = "huebie.family";
  vhosts = [
    {
      domain = domain;
      subdomain = "paperless";
      ip = "100.93.235.96";
      port = 30070;
    }
    {
      domain = domain;
      subdomain = "immich";
      ip = "100.93.235.96";
      port = 30041;
    }
    {
      domain = domain;
      subdomain = "home";
      ip = "100.93.235.96";
      port = 8123;
    }
    {
      domain = domain;
      subdomain = "nextcloud";
      ip = "100.93.235.96";
      port = 30027;
    }
    {
      domain = domain;
      subdomain = "mail-archive";
      ip = "100.93.235.96";
      port = 30315;
    }
  ];
in {
  options.vps.proxy.enable = lib.mkEnableOption "proxying for my parents";

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts = builtins.listToAttrs (map (v: {
        name = "${v.subdomain}.${v.domain}";
        value = {
          extraConfig = ''
            tls {
              dns hetzner {env.HZTOKEN}
            }
            reverse_proxy ${v.ip}:${toString v.port}
          '';
        };
      })
      vhosts);
  };
}
