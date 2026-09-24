{
  pkgs,
  config,
  lib,
  ...
}: let
  sshKeys = import ../ssh-keys.nix;
  mediaDir = "/var/lib/swiftster/media";
  port = 3000;
  origin = "hitdeck.de";
in {
  vps = {
    nixosFlakeHost = "ryloth";
    secrets.sopsFile = ../../secrets/ryloth.enc.yaml;
    nixStorage.enable = true;
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.swiftster = {
    # Pinned so a rebuild is reproducible; the customManager in
    # ../../renovate.json bumps this tag and auto-merges the PR, which in
    # turn fires .github/workflows/update-ryloth.yaml to rebuild.
    image = "ghcr.io/titusio/swiftster:0.1.0";
    autoStart = true;

    ports = ["127.0.0.1:${toString port}:3000"];

    volumes = ["${mediaDir}:/music:ro"];

    environment = {
      MEDIA_DIR = "/music";
      ORIGIN = "${origin}"; # must match PUBLIC_ORIGIN
    };
  };

  # podman refuses to start when a bind mount's source is missing
  systemd.tmpfiles.rules = ["d ${mediaDir} 0755 root root -"];

  services.caddy.virtualHosts."${origin}".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString port}
  '';

  networking.firewall.allowedTCPPorts = [80 443];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "ryloth";

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
