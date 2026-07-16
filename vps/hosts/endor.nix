{
  pkgs,
  config,
  lib,
  ...
}: let
  sshKeys = import ../ssh-keys.nix;
in {
  vps = {
    nixosFlakeHost = "endor";
    secrets.sopsFile = ../../secrets/endor.enc.yaml;
    nixStorage.enable = true;
    pocketId.enable = true;
    gatus = {
      enable = true;
      domain = "status.titusio.net";
      auth = {
        enable = true;
        clientId = "faa246bf-1c4f-49a6-98a3-db3ae538800b";
      };
      ntfy.enable = true;
      settings = {
        endpoints = [
          {
            name = "titusio.net";
            url = "https://titusio.net";
            conditions = [
              "[STATUS] == 200"
              "[BODY] == I was hoping for Kenobi"
            ];
            alerts = [{type = "ntfy";}];
          }
        ];
      };
    };
  };

  services.caddy.virtualHosts."nextcloud.titusio.net".extraConfig = ''
    # scarif tailscale ip
    reverse_proxy 100.118.60.94:30027
  '';

  networking.firewall.allowedTCPPorts = [22 80 443];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "endor";

  users.users.root = {
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.titus = {
    isNormalUser = true;
    description = "titus";
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = sshKeys;
  };

  system.stateVersion = "26.05";
}
