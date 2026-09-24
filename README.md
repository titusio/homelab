# homelab

Configuration files for my kubernetes cluster at home. 

## Talos / Kubernetes

See [talos/README.md](talos/README.md) for how to update the cluster.

For bootstrapping Flux and Cilium on a fresh cluster, see [kubernetes/README.md](kubernetes/README.md).

## Ryloth

Ryloth is the homeworld of the Twi'lek species, a harsh world in the Outer Rim Territories that is tidally locked, leaving one hemisphere in perpetual day and the other in perpetual night.

It hosts [Swiftster](https://github.com/titusio/swiftster).

### Install

On first-time setup, generate a dedicated age key for ryloth and encrypt it with your personal key:

```shell
# Generate age key (one time only)
age-keygen -o secrets/ryloth.age

# Get the public key and update .sops.yaml with it
age-keygen -y secrets/ryloth.age

# Encrypt it
sops -e secrets/ryloth.age > secrets/ryloth.enc.age
rm secrets/ryloth.age

# Create and encrypt the secrets file
sops secrets/ryloth.enc.yaml
```

To deploy:

```shell
# Decrypt the age key and stage it for nixos-anywhere
mkdir -p .deploy/root/.config/sops/age
sops -d secrets/ryloth.enc.age \
  > .deploy/root/.config/sops/age/keys.txt
chmod 600 .deploy/root/.config/sops/age/keys.txt

# Deploy
nix run github:nix-community/nixos-anywhere -- \
  --extra-files .deploy \
  --flake .#ryloth root@<server-ip>
```

> The `--extra-files` flag provisions the age key onto the server before activation. The files mirror the target filesystem, so `.deploy/root/.config/sops/age/keys.txt` is placed at `/root/.config/sops/age/keys.txt` on the server, allowing sops-nix to decrypt secrets on first boot.

### GitHub Deploy Key

Add the following public key as a read-only deploy key on this repository:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFMXPWiXNrbprHK4uh8yODytutGfNXmpqON43t4xckga corellian
```

### Update

```shell
nixos-rebuild switch --flake .#ryloth --target-host root@<server-ip>
```

The flake is updated daily at midnight UTC via a GitHub Actions workflow, which opens and auto-merges a PR. The server then picks up the changes automatically at 04:00 UTC via `system.autoUpgrade`.

## Endor

Endor hosts [Pocket ID](https://github.com/pocket-id/pocket-id), an OIDC provider.

### GitHub Deploy Key

Add the following public key as a read-only deploy key on this repository:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnCqfm3j0JVl/JSTzfGtpX28TklBKxuIP85WgMk8f+ endor@homelab
```

### Install

```shell
# Generate age key (one time only)
age-keygen -o secrets/endor.age

# Get the public key and update .sops.yaml with it
age-keygen -y secrets/endor.age

# Encrypt it
sops -e secrets/endor.age > secrets/endor.enc.age
rm secrets/endor.age

# Create and encrypt the secrets file
sops secrets/endor.enc.yaml
```

To deploy:

```shell
# Decrypt the age key and stage it for nixos-anywhere
mkdir -p .deploy/root/.config/sops/age
sops -d secrets/endor.enc.age \
  > .deploy/root/.config/sops/age/keys.txt
chmod 600 .deploy/root/.config/sops/age/keys.txt

# Deploy
nix run github:nix-community/nixos-anywhere -- \
  --extra-files .deploy \
  --flake .#endor root@<server-ip>
```

### Update

```shell
nixos-rebuild switch --flake .#endor --target-host root@<server-ip>
```
