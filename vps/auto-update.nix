{
  config,
  lib,
  ...
}: let
  cfg = config.vps.autoUpdate;
in {
  options.vps.autoUpdate.enable = lib.mkEnableOption "VPS auto-upgrade";

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "git+ssh://git@github.com/titusio/homelab#corellian";
      flags = [
      ];
      rebootWindow = {
        lower = "01:00";
        upper = "05:00";
      };
      dates = "04:00 UTC";
      randomizedDelaySec = "45min";
    };
  };
}
