{
  pkgs,
  config,
  lib,
  ...
}: let
  sshKeys = import ../ssh-keys.nix;
in {
  vps = {
    nixosFlakeHost = "mandalore";
    pixelfed.enable = true;
    secrets.sopsFile = ../../secrets/mandalore.enc.yaml;
    nixStorage.enable = true;
    # Pixelfed's arion stack runs on podman
    podman.enable = true;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "mandalore";

  users.users.root = {
    openssh.authorizedKeys.keys = sshKeys;
    hashedPassword = "$y$j9T$z0qkq4CO0zjt6sWMSCr3F1$SxmTlWvlTbhqmWmQwvGz4VEEGme6gTNMBylBY6a4R61";
  };

  users.users.titus = {
    isNormalUser = true;
    description = "titus";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = sshKeys;
    hashedPassword = "$y$j9T$wvQP3cnSOD1YU2WI1nmJF.$pPbuf1534WJi2hcFsnWqd.nw7r35x2KRoN/DcMvM08A";
    # stop podman containers from exiting on ssh logout
    linger = true;
  };

  # lazygit, neovim and git come from vps/default.nix
  environment.systemPackages = with pkgs; [
    unixtools.netstat
  ];

  system.stateVersion = "26.05";
}
