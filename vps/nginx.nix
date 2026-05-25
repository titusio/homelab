{...}: {
  services.nginx = {
    enable = true;
    streamConfig = ''
      resolver 100.100.100.100 valid=30s;

      server {
        listen 443;
        set $upstream traefik-vps-ingress-tailscale.donkey-betta.ts.net:443;
        proxy_pass $upstream;
      }
      server {
        listen 80;
        set $upstream traefik-vps-ingress-tailscale.donkey-betta.ts.net:80;
        proxy_pass $upstream;
      }
    '';
  };
}
