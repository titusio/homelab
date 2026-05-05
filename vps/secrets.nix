{config, ...}: {
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";

    secrets = {
      "git/sshKey" = {
        path = "/root/.ssh/id_ed25519";
        mode = "0600";
      };
    };
  };
}
