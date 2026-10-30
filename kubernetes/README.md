# Kubernetes

GitOps managed with [Flux](https://fluxcd.io/).

## Structure

```
kubernetes/
├── clusters/
│   └── outerrim/
│       ├── flux-system/       # Flux components (generated, do not edit)
│       ├── secrets/            # SOPS-encrypted secrets for this cluster only
│       ├── infrastructure.yaml # Kustomization -> infrastructure/outerrim
│       └── apps.yaml           # Kustomization -> apps/outerrim
├── infrastructure/
│   ├── base/
│   │   └── cilium/             # CNI, shared by every cluster
│   ├── providers/
│   │   └── hetzner/            # provider-specific infra, opt-in per cluster
│   └── outerrim/                # per-cluster selection of base/ + providers/
└── apps/
    ├── <app>/                  # one folder per app, shared definition
    └── outerrim/                # per-cluster selection of apps
```

## Bootstrapping

After a fresh cluster (or full reset), Cilium and the Hetzner Cloud Controller Manager must be
installed manually before Flux can run — Flux pods need a working CNI, and Talos nodes come up
with the `node.cloudprovider.kubernetes.io/uninitialized` taint (from `externalCloudProvider` in
`talconfig.yaml`) until hccm removes it, so nothing schedules until both are up. Both are
otherwise managed by Flux afterwards.

### Prerequisites

- `helm` and `flux` CLIs installed
- `GITHUB_TOKEN` env var set with a token that has `repo` scope
- kubeconfig pointing at the cluster

### 1. Install Cilium manually

Talos runs without kube-proxy (KubePrism on port 7445 replaces it), so use the without-kube-proxy method from the
[Talos Cilium guide](https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium):

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
  --version 1.20.4 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445
```

> Note: Talos will appear to hang with "node not ready" messages until the CNI is operational — this is expected.

Wait for Cilium to be ready before continuing:

```bash
kubectl -n kube-system rollout status daemonset/cilium
```

### 2. Install the Hetzner Cloud Controller Manager manually

The node stays tainted (`node.cloudprovider.kubernetes.io/uninitialized:NoSchedule`) until hccm
runs and confirms the node with the Hetzner API, so this has to happen before anything else
(including Flux) can schedule normally.

Create the `hetzner-cloud-key` secret with a [Hetzner API token](https://console.hetzner.cloud/)
(read+write, scoped to this project):

```bash
kubectl create secret generic hetzner-cloud-key \
  --namespace kube-system \
  --from-literal=token=<HCLOUD_TOKEN>
```

Then install hccm:

```bash
helm repo add hcloud https://charts.hetzner.cloud
helm repo update

helm install hccm hcloud/hcloud-cloud-controller-manager \
  --version 1.39.2 \
  --namespace kube-system
```

Wait for the taint to clear and the node to go `Ready`:

```bash
kubectl get nodes -o wide
```

### 3. Create the SOPS decryption secret

Secrets for this cluster live SOPS-encrypted in git under
`clusters/outerrim/secrets/` (only the `.sops.yaml` rule for this cluster's own path can decrypt
them — other clusters can't), decrypted in-cluster by Flux. Only the `data`/`stringData` fields
are encrypted; everything else (`apiVersion`, `kind`, `metadata`, ...) stays plaintext so diffs
stay readable. Create the `sops-age` secret Flux decrypts them with:

```bash
just create-sops-secret
```

This decrypts `secrets/outerrim.enc.age` (the cluster's dedicated age identity, itself
SOPS-encrypted with your personal key) and loads it into the `flux-system` namespace.

### 4. Bootstrap Flux

```bash
flux bootstrap github \
  --owner=titusio \
  --repository=homelab \
  --branch=main \
  --path=kubernetes/clusters/outerrim \
  --token-auth \
  --decryption-provider=sops \
  --decryption-secret=sops-age
```

This creates the `flux-system` secret in the cluster with the GitHub token. If the manifests in
`flux-system/` are unchanged, no new commit is made. The `--decryption-*` flags keep the
decryption config in `flux-system/gotk-sync.yaml` across bootstrap reruns.

Flux will then take over managing Cilium via the HelmRelease in `infrastructure/base/cilium/`,
and any provider-specific infra (e.g. `infrastructure/providers/hetzner/`) along with the
secrets it needs from `secrets.enc.yaml`.

### Verify

```bash
flux get all -A
```

All sources and kustomizations should show `Ready: True` within a few minutes.
