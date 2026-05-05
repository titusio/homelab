# homelab

Configuration files for my kubernetes cluster at home. 

## Corellian

The Corellian Run was a super-hyperroute that ran throughout the various regions of the galaxy, starting at the planet Coruscant in the Core Worlds and ending at Naos and Lamaredd. The hyperroute also passed through the Hetzal and Ab Dalis systems.

Here it is used as a reverse proxy to route traffic to the various services running in the cluster using [Wiredoor](https://www.wiredoor.net/). 

### Install

Boot the target into a live installer, then run:

```shell
nix run github:nix-community/nixos-anywhere -- --flake .#corellian root@<server-ip>
```

### Update

```shell
nixos-rebuild switch --flake .#corellian --target-host root@<server-ip>
```

The flake is updated daily at midnight UTC via a GitHub Actions workflow, which opens and auto-merges a PR. The server then picks up the changes automatically at 04:00 UTC via `system.autoUpgrade`.
