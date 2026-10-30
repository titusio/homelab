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
    services.pangolin = {
        enable = true;
        settings = {
          flags = {
            disable_signup_without_invite = true;
            disable_user_create_org = true;
          };
        };
        baseDomain = "tituscloud.dev";
        letsEncryptEmail = "letsEncrypt@titusmail.de"; # an email you have access to
        openFirewall = true;
        environmentFile = config.sops.secrets."pangolin/env".path;
      };
  };
}
