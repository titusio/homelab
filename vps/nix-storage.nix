{
  config,
  lib,
  ...
}: let
  cfg = config.vps.nixStorage;
in {
  options.vps.nixStorage.enable = lib.mkEnableOption "Nix store optimisation and GC";

  config = lib.mkIf cfg.enable {
    nix.optimise.automatic = true;
    nix.optimise.dates = ["03:45"];

    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };
  };
}
