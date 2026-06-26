{
  pkgs,
  config,
  lib,
  ...
}: let
  sshKeys = import ../ssh-keys.nix;
in {
  vps = {
    firewall.enable = true;
    autoUpdate.enable = true;
    webhook.enable = true;
    secrets.enable = true;
    nixStorage.enable = true;
    tailscale.enable = true;
    nginx.enable = true;
  };

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "corellian-run";

  users.users.root = {
    hashedPassword = "$y$j9T$sm19yaRkje0AOBwW/pTRt.$MntXjJC6P.rGgdG64rvTOKATAxDoggPXyIADTBFx8B.";
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.titus = {
    isNormalUser = true;
    description = "titus";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = sshKeys;
    hashedPassword = "$y$j9T$b4Dv7lAK98k1KzH7Ef1QM.$79C6YqFZCeA9.Zz5e6uO2TKmSjzqIttFDv6wbIDSMm9";
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    lazygit
    neovim
    git
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
    # we proxy 22 to the cluster because forgejo needs it.
    ports = [20022];
  };

  programs.ssh.knownHosts = {
    github = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };

  system.stateVersion = "26.05";
}
