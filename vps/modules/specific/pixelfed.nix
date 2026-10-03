{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.vps.pixelfed;
  dataDir = "/var/lib/pixelfed";
  domain = "pixelfed.whiled.net";
  port = 8080;
  image = "ghcr.io/pixelfed/pixelfed:v0.14.4";

  # non-secret part of the upstream .env; the secrets come in via the sops
  # templates below
  pixelfedEnv = {
    APP_NAME = "Pixelfed";
    APP_ENV = "production";
    APP_DEBUG = "false";

    OPEN_REGISTRATION = "false";
    ENFORCE_EMAIL_VERIFICATION = "false";
    PF_MAX_USERS = "1000";
    OAUTH_ENABLED = "true";
    ENABLE_CONFIG_CACHE = "true";
    INSTANCE_DISCOVER_PUBLIC = "true";
    STORIES_ENABLED = "true";

    PF_OPTIMIZE_IMAGES = "true";
    IMAGE_QUALITY = "80";
    MAX_PHOTO_SIZE = "15000";
    MAX_CAPTION_LENGTH = "500";
    MAX_ALBUM_LENGTH = "4";

    APP_URL = "https://${domain}";
    APP_DOMAIN = domain;
    ADMIN_DOMAIN = domain;
    SESSION_DOMAIN = domain;
    TRUST_PROXIES = "*";

    DB_CONNECTION = "mysql";
    DB_HOST = "db";
    DB_PORT = "3306";
    DB_DATABASE = "pixelfed";
    DB_USERNAME = "pixelfed";

    REDIS_CLIENT = "predis";
    REDIS_SCHEME = "tcp";
    REDIS_HOST = "redis";
    REDIS_PASSWORD = "null";
    REDIS_PORT = "6379";

    SESSION_DRIVER = "database";
    CACHE_DRIVER = "redis";
    QUEUE_DRIVER = "redis";
    BROADCAST_DRIVER = "log";
    LOG_CHANNEL = "stack";
    HORIZON_PREFIX = "horizon-";

    ACTIVITY_PUB = "false";
    AP_REMOTE_FOLLOW = "false";
    AP_INBOX = "false";
    AP_OUTBOX = "false";
    AP_SHAREDINBOX = "false";

    EXP_EMC = "true";

    MAIL_DRIVER = "smtp";
    MAIL_HOST = "smtp.mailgun.org";
    MAIL_PORT = "587";
    MAIL_ENCRYPTION = "tls";
    MAIL_FROM_ADDRESS = "pixelfed@mail.whiled.net";
    MAIL_FROM_NAME = "Pixelfed";

    PF_ENABLE_CLOUD = "false";
    FILESYSTEM_CLOUD = "s3";

    PHP_POST_MAX_SIZE = "500M";
    PHP_UPLOAD_MAX_FILE_SIZE = "500M";
    PHP_OPCACHE_ENABLE = "1";
  };

  # horizon and the scheduler only differ from the app in what they autorun
  autorun = {
    migrate ? false,
    caches ? false,
  }: {
    AUTORUN_ENABLED = lib.boolToString migrate;
    AUTORUN_LARAVEL_MIGRATION = lib.boolToString migrate;
    AUTORUN_LARAVEL_MIGRATION_ISOLATION = lib.boolToString migrate;
    AUTORUN_LARAVEL_STORAGE_LINK = "true";
    AUTORUN_LARAVEL_EVENT_CACHE = lib.boolToString caches;
    AUTORUN_LARAVEL_ROUTE_CACHE = "false";
    AUTORUN_LARAVEL_VIEW_CACHE = lib.boolToString caches;
    AUTORUN_LARAVEL_CONFIG_CACHE = "true";
  };

  pixelfedService = {
    inherit image;
    restart = "unless-stopped";
    env_file = [config.sops.templates."pixelfed.env".path];
    volumes = ["${dataDir}/storage:/var/www/html/storage"];
    depends_on = ["db" "redis"];
  };

  secret = name: config.sops.placeholder."pixelfed/${name}";

  # arion's NixOS container module still sets services.journald.console, which
  # nixpkgs removed; the failed assertion breaks arion's test suite
  arionSrc = pkgs.applyPatches {
    name = "arion-src";
    src = inputs.arion;
    postPatch = ''
      substituteInPlace src/nix/modules/nixos/container-systemd.nix \
        --replace-fail 'services.journald.console = "/dev/console";' \
          'services.journald.settings.Journal = { ForwardToConsole = true; TTYPath = "/dev/console"; };'
    '';
  };
in {
  imports = [inputs.arion.nixosModules.arion];

  options.vps.pixelfed.enable = lib.mkEnableOption "Pixelfed via arion";

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "pixelfed/app_key" = {};
      "pixelfed/db_password" = {};
      "pixelfed/db_root_password" = {};
      "pixelfed/mail_username" = {};
      "pixelfed/mail_password" = {};
    };

    sops.templates."pixelfed.env".content = ''
      APP_KEY=${secret "app_key"}
      DB_PASSWORD=${secret "db_password"}
      MAIL_USERNAME=${secret "mail_username"}
      MAIL_PASSWORD=${secret "mail_password"}
    '';

    sops.templates."pixelfed-db.env".content = ''
      MYSQL_PASSWORD=${secret "db_password"}
      MYSQL_ROOT_PASSWORD=${secret "db_root_password"}
    '';

    virtualisation.arion = {
      backend = "podman-socket";
      package = (import arionSrc {inherit pkgs;}).arion;
      projects.pixelfed.settings.services = {
        db.service = {
          image = "mysql:8";
          container_name = "pixelfed-db";
          restart = "unless-stopped";
          env_file = [config.sops.templates."pixelfed-db.env".path];
          environment = {
            MYSQL_DATABASE = pixelfedEnv.DB_DATABASE;
            MYSQL_USER = pixelfedEnv.DB_USERNAME;
          };
          volumes = ["${dataDir}/mysql:/var/lib/mysql"];
          healthcheck = {
            # $$ escapes compose's interpolation so the container's shell
            # expands it instead
            test = ["CMD" "mysqladmin" "ping" "-h" "127.0.0.1" "-u" "root" "-p$$MYSQL_ROOT_PASSWORD"];
            interval = "10s";
            timeout = "5s";
            retries = 3;
            start_period = "30s";
          };
        };

        redis.service = {
          image = "redis:7-alpine";
          container_name = "pixelfed-redis";
          restart = "unless-stopped";
          command = ["redis-server" "--appendonly" "yes"];
          volumes = ["${dataDir}/redis:/data"];
          healthcheck = {
            test = ["CMD" "redis-cli" "ping"];
            interval = "10s";
            timeout = "3s";
            retries = 3;
            start_period = "10s";
          };
        };

        pixelfed.service =
          pixelfedService
          // {
            container_name = "pixelfed-app";
            ports = ["127.0.0.1:${toString port}:8080"];
            environment =
              pixelfedEnv
              // autorun {
                migrate = true;
                caches = true;
              }
              // {
                # TLS is terminated by the host's caddy
                SSL_MODE = "off";
                LOG_OUTPUT_LEVEL = "error";
                CADDY_SERVER_EXTRA_DIRECTIVES = ''
                  @service_worker path /sw.js
                  header @service_worker Cache-Control "no-cache"
                '';
              };
          };

        horizon.service =
          pixelfedService
          // {
            container_name = "pixelfed-horizon";
            command = ["php" "artisan" "horizon"];
            environment = pixelfedEnv // autorun {};
            healthcheck = {
              test = ["CMD" "php" "artisan" "horizon:status"];
              interval = "10s";
              timeout = "5s";
              retries = 3;
            };
          };

        scheduler.service =
          pixelfedService
          // {
            container_name = "pixelfed-scheduler";
            command = ["php" "artisan" "schedule:work"];
            stop_signal = "SIGTERM";
            environment = pixelfedEnv // autorun {};
            healthcheck = {
              test = ["CMD" "healthcheck-schedule"];
              start_period = "10s";
            };
          };
      };
    };

    # bind mount sources have to exist; the pixelfed image runs as www-data (33)
    # and doesn't chown its storage, mysql and redis fix up their own dirs
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/mysql 0755 root root -"
      "d ${dataDir}/redis 0755 root root -"
      "d ${dataDir}/storage 0755 33 33 -"
    ];

    services.caddy.virtualHosts.${domain}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };
}
