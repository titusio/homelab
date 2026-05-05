# GitHub Action → Tailscale Webhook

## How it works

A GitHub Action joins your Tailscale network as an ephemeral node on every push to `main`, then fires an HTTP webhook at a server on your tailnet.

```
GitHub Push → Action Runner joins tailnet (tag:ci) → curl → corellian:9000 → NixOS rebuild
```

## Setup

### 1. Tailscale OAuth Client
Create an OAuth client at **Settings → OAuth clients** with:
- Scope: **Keys → Auth Keys → Write**
- Tag: `tag:ci`

### 2. Tailscale ACL
```json
"tagOwners": {
    "tag:ci":          ["autogroup:admin"],
    "tag:public-prod": ["autogroup:admin"]
},
"grants": [
    {
        "src": ["tag:ci"],
        "dst": ["tag:public-prod"],
        "ip":  ["tcp:22", "tcp:9000"]
    }
]
```

### 3. GitHub Secrets
| Secret | Value |
|---|---|
| `TS_OAUTH_CLIENT_ID` | OAuth client ID |
| `TS_OAUTH_CLIENT_SECRET` | OAuth client secret |

### 4. Workflow
```yaml
- name: Connect Tailscale
  uses: tailscale/github-action@v4
  with:
    oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
    oauth-secret: ${{ secrets.TS_OAUTH_CLIENT_SECRET }}
    tags: tag:ci

- name: Trigger NixOS rebuild
  run: curl -X POST http://corellian:9000/hooks/nixos-rebuild
```

## Gotchas
- OAuth scope must be **Auth Keys → Write**, not Devices → Core
- The target server must be tagged `tag:public-prod` in Tailscale
- ACL must explicitly allow `tcp:9000` from `tag:ci` to `tag:public-prod`
- The ephemeral runner node is automatically removed after the job finishes
- Use `git+ssh://git@github.com/org/repo` not `github:org/repo` as the flake URL — the `github:` fetcher uses HTTPS and returns 404 for private repos
- GitHub's SSH host key must be declared in NixOS via `programs.ssh.knownHosts`, otherwise the SSH handshake fails silently
- Do not run the webhook service as root. Instead create a dedicated systemd oneshot service for the rebuild and allow the `webhook` user to start it via `security.sudo.extraRules`
- In NixOS, the setuid `sudo` binary is at `/run/wrappers/bin/sudo`, not `/run/current-system/sw/bin/sudo` — using the wrong path produces `must be owned by uid 0 and have the setuid bit set`
- SSH private keys stored in sops must use a YAML block scalar (`|`) to preserve newlines — a quoted string with `\n` escapes produces a malformed key file and `error in libcrypto: unsupported`
