{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./firewall.nix
    ./auto-update.nix
    ./webhook.nix
    ./secrets.nix
    ./nix-storage.nix
    ./tailscale.nix
    ./nginx.nix
  ];
}
