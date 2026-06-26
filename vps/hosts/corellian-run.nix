{
  pkgs,
  config,
  lib,
  ...
}: let
  sshKeys = import ../ssh-keys.nix;
in {
  vps = {
    nixosFlakeHost = "corellian";
    secrets.sopsFile = ../../secrets/corellian.enc.yaml;
    nixStorage.enable = true;
    nginx.enable = true;
  };

  networking.firewall.allowedTCPPorts = [22 80 443];

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

  system.stateVersion = "26.05";
}
