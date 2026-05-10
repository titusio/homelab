# Decrypt talos secrets and client config from secrets/ into talos/
decrypt-talos:
    @sops --decrypt secrets/talos-secrets.enc.yaml > talos/secrets.yaml
    @sops --decrypt --output-type yaml secrets/talosconfig.enc.yaml > talos/talosconfig

# Encrypt talos secrets and client config from talos/ into secrets/
encrypt-talos:
    @sops --encrypt talos/secrets.yaml > secrets/talos-secrets.enc.yaml
    @sops --encrypt --input-type yaml --output-type yaml talos/talosconfig > secrets/talosconfig.enc.yaml
