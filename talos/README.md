# Talos

Cluster config managed with [talhelper](https://github.com/budimanjojo/talhelper).
Secrets encrypted with SOPS + age.

## Prerequisites

- `talhelper`
- `talosctl`
- `sops` with the age key for `age1ywn62vszqd5n9g4v3rphmqc620t7u852xzctzk80afp4vu57n45qdqhlem`

## Updating the cluster

### 1. Make changes

Edit `talconfig.yaml` or the patch files (`longhorn-extension-patch.yaml`,
`tailscale-extension-patch.yaml`) as needed.

To bump the Talos version, update `talosVersion` in `talconfig.yaml`.

### 2. Regenerate configs

```bash
talhelper genconfig
```

Output goes to `clusterconfig/` (gitignored).

### 3. Apply to nodes

```bash
export TALOSCONFIG=clusterconfig/talosconfig

# Apply to all nodes
talhelper gencommand apply | bash

# Or apply to a specific node
talosctl apply-config --nodes 10.0.40.11 --file clusterconfig/core-worlds-corellia.yaml
```

### Upgrading Talos

After bumping `talosVersion` and regenerating:

```bash
talhelper gencommand upgrade | bash
```

### Adding a Tailscale auth key

Fill in the key in `tailscale-extension-patch.yaml` before regenerating:

```yaml
environment:
  - TS_AUTHKEY=tskey-auth-...
```

Do not commit the key.
