# Kubernetes

GitOps managed with [Flux](https://fluxcd.io/).

## Structure

```
kubernetes/
├── flux-system/       # Flux components (generated, do not edit)
└── infrastructure/    # Cluster infrastructure
    └── kube-system/
        └── cilium/    # CNI
```

## Bootstrapping

After a fresh cluster (or full reset), Cilium must be installed manually before Flux can run —
Flux pods need a working CNI, but Cilium is otherwise managed by Flux.

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
  --version 1.18.0 \
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

### 2. Bootstrap Flux

```bash
flux bootstrap github \
  --owner=titusio \
  --repository=homelab \
  --branch=main \
  --path=kubernetes \
  --token-auth
```

This creates the `flux-system` secret in the cluster with the GitHub token. If the manifests in
`flux-system/` are unchanged, no new commit is made.

Flux will then take over managing Cilium via the HelmRelease in `infrastructure/kube-system/cilium/`.

### Verify

```bash
flux get all -A
```

All sources and kustomizations should show `Ready: True` within a few minutes.
