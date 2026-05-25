{...}: {
  services.nginx = {
    enable = true;
    streamConfig = ''
      upstream k8s_https {
        server traefik-vps-ingress-tailscale.donkey-betta.ts.net:443;
      }
      upstream k8s_http {
        server traefik-vps-ingress-tailscale.donkey-betta.ts.net:80;
      }
      server {
        listen 443;
        proxy_pass k8s_https;
      }
      server {
        listen 80;
        proxy_pass k8s_http;
      }
    '';
  };
}
