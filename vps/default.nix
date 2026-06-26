{
  lib,
  pkgs,
  ...
}: {
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
    ./openssh.nix
  ];

  vps = {
    firewall.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
    secrets.enable = lib.mkDefault true;
    webhook.enable = lib.mkDefault true;
    autoUpdate.enable = lib.mkDefault true;
    openssh.enable = lib.mkDefault true;
  };

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
