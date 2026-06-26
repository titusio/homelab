{
  config,
  lib,
  ...
}: let
  cfg = config.vps.firewall;
in {
  options.vps.firewall.enable = lib.mkEnableOption "VPS firewall";

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = true;
  };
}
