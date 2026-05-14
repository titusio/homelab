{
  config,
  pkgs,
  ...
}: let
  port = 51820;
  subnet = "10.10.0.0/24";
  crowdsecExtras = "/etc/wiredoor/extras/crowdsec";
in {
  sops.secrets."wiredoor/adminEmail" = {};
  sops.secrets."wiredoor/adminPassword" = {};

  sops.templates."wiredoor-env".content = ''
    ADMIN_EMAIL=${config.sops.placeholder."wiredoor/adminEmail"}
    ADMIN_PASSWORD=${config.sops.placeholder."wiredoor/adminPassword"}

    VPN_HOST=door.tituscloud.dev
    VPN_PORT=${toString port}
    VPN_SUBNET=${subnet}

    TZ=Europe/Berlin
  '';

  environment.etc = {
    "wiredoor/docker-compose.yml".text = ''
      services:
        wiredoor:
          image: wiredoor/wiredoor:latest
          container_name: wiredoor
          cap_add:
            - NET_ADMIN
          env_file:
            - ${config.sops.templates."wiredoor-env".path}
          restart: unless-stopped
          volumes:
            - wiredoor-data:/data
            - wiredoor-certbot:/etc/letsencrypt
            - wiredoor-logs:/var/log/nginx
          ports:
            - 80:80/tcp
            - 443:443/tcp
            - 443:443/udp
            - ${toString port}:${toString port}/udp
          dns:
            - 9.9.9.9
            - 149.112.112.112
          sysctls:
            net.ipv4.ip_forward: 1
          networks:
            - wiredoor

        crowdsec:
          image: crowdsecurity/crowdsec:latest
          container_name: crowdsec
          restart: unless-stopped
          volumes:
            - crowdsec-data:/var/lib/crowdsec/data/
            - wiredoor-logs:/var/log/nginx:ro
            - ${crowdsecExtras}/acquis.d:/etc/crowdsec/acquis.d:ro
          environment:
            COLLECTIONS: crowdsecurity/nginx
            TZ: America/New_York
            GID: "1000"
          ports:
            - 127.0.0.1:8080:8080
          healthcheck:
            test: ["CMD", "cscli", "lapi", "status"]
            interval: 15s
            timeout: 10s
            retries: 4
            start_period: 30s
          networks:
            - wiredoor

      volumes:
        wiredoor-data:
        wiredoor-certbot:
        wiredoor-logs:
        crowdsec-data:

      networks:
        wiredoor:
    '';

    "wiredoor/extras/crowdsec/acquis.d/nginx.yaml".text = ''
      source: file
      filenames:
        - /var/log/nginx/*.log
      labels:
        type: nginx
    '';
  };

  virtualisation.docker.enable = true;

  systemd.services.wiredoor = {
    description = "Wiredoor docker-compose stack";
    after = ["docker.service" "network-online.target" "sops-nix.service"];
    requires = ["docker.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/wiredoor";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --remove-orphans";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    };
  };
}
