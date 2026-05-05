{
  pkgs,
  config,
  lib,
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
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "corellian";

  users.users.root = {
    hashedPassword = "$y$j9T$sm19yaRkje0AOBwW/pTRt.$MntXjJC6P.rGgdG64rvTOKATAxDoggPXyIADTBFx8B.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZAMR7ANTdIik3dYOG/oDHKzE7GhKjHSRwuhcWWtSUM titus@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRkA6GHUlDJRacyT9dx0bbUdu6MVyhgRGe3QLb6UhWn titus@coruscant"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHEm75mX3Tsdt7tksWXcvu3RGGJvIj9xi+ZC/jkqx2c titus@Tituss-MacBook-Pro.local"
    ];
  };

  users.users.titus = {
    isNormalUser = true;
    description = "titus";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZAMR7ANTdIik3dYOG/oDHKzE7GhKjHSRwuhcWWtSUM titus@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINRkA6GHUlDJRacyT9dx0bbUdu6MVyhgRGe3QLb6UhWn titus@coruscant"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHEm75mX3Tsdt7tksWXcvu3RGGJvIj9xi+ZC/jkqx2c titus@Tituss-MacBook-Pro.local"
    ];
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
  };

  programs.ssh.knownHosts = {
    github = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };

  system.stateVersion = "26.05";
}
