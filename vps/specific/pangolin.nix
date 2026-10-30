{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vps.pangolin;
in
{
  options.vps.pangolin.enable = lib.mkEnableOption "Pangolin";
  # PER-831E6EC9-AAEE-4E18-BF79-1E4182BE472D
  config = lib.mkIf cfg.enable {
    services.pangolin = {
        enable = true;
        package = pkgs.fosrl-pangolin.override { edition = "enterprise"; };
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
