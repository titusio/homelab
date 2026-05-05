# homelab

Configuration files for my kubernetes cluster at home. 

## Corellian

The Corellian Run was a super-hyperroute that ran throughout the various regions of the galaxy, starting at the planet Coruscant in the Core Worlds and ending at Naos and Lamaredd. The hyperroute also passed through the Hetzal and Ab Dalis systems.

Here it is used as a reverse proxy to route traffic to the various services running in the cluster using [Wiredoor](https://www.wiredoor.net/). 

### Install

On first-time setup, generate a dedicated age key for corellian and encrypt it with your personal key:

```shell
# Generate age key (one time only)
age-keygen -o secrets/corellian.age

# Get the public key and update .sops.yaml with it
age-keygen -y secrets/corellian.age

# Encrypt it
sops -e secrets/corellian.age > secrets/corellian.enc.age
rm secrets/corellian.age

# Create and encrypt the secrets file
sops secrets/secrets.yaml
```

To deploy:

```shell
# Decrypt the age key and stage it for nixos-anywhere
mkdir -p .deploy/root/.config/sops/age
sops -d secrets/corellian.enc.age \
  > .deploy/root/.config/sops/age/keys.txt
chmod 600 .deploy/root/.config/sops/age/keys.txt

# Deploy
nix run github:nix-community/nixos-anywhere -- \
  --extra-files .deploy \
  --flake .#corellian root@<server-ip>
```

> The `--extra-files` flag provisions the age key onto the server before activation. The files mirror the target filesystem, so `.deploy/root/.config/sops/age/keys.txt` is placed at `/root/.config/sops/age/keys.txt` on the server, allowing sops-nix to decrypt secrets on first boot.

### GitHub Deploy Key

Add the following public key as a read-only deploy key on this repository:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFMXPWiXNrbprHK4uh8yODytutGfNXmpqON43t4xckga corellian
```

### Update

```shell
nixos-rebuild switch --flake .#corellian --target-host root@<server-ip>
```

The flake is updated daily at midnight UTC via a GitHub Actions workflow, which opens and auto-merges a PR. The server then picks up the changes automatically at 04:00 UTC via `system.autoUpgrade`.
