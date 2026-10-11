{
  config,
  lib,
  ...
}:
let
  cfg = config.vps.pangolin;
in
{
  options.vps.pangolin.enable = lib.mkEnableOption "Pangolin";

  config = lib.mkIf cfg.enable {
  };
}
