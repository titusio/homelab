{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./caddy.nix
    ./proxy.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./firewall.nix
    ./auto-update.nix
    ./webhook.nix
    ./secrets.nix
    ./nix-storage.nix
    ./tailscale.nix
    ./openssh.nix
    ./pocket-id.nix
    ./gatus.nix
  ];

  vps = {
    firewall.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
    secrets.enable = lib.mkDefault true;
    webhook.enable = lib.mkDefault true;
    autoUpdate.enable = lib.mkDefault true;
    openssh.enable = lib.mkDefault true;
    caddy.enable = lib.mkDefault true;
  };

  # nh, system.autoUpgrade and the rebuild webhook all deploy from a flake
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    lazygit
    neovim
    git
  ];

  programs.ssh.knownHosts = {
    github = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };
}
