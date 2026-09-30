{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.vps.podman;
in {
  options.vps.podman.enable = lib.mkEnableOption "Podman container runtime";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
    };

    virtualisation.oci-containers.backend = "podman";

    # podman itself comes with virtualisation.podman.enable
    environment.systemPackages = with pkgs; [
      podman-tui
      podman-compose
    ];
  };
}
