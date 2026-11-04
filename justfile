# Creates the Flux SOPS secret inside the cluster.
create-sops-secret:
    @sops -d ./secrets/outerrim.enc.age | \
        kubectl create secret generic sops-age \
            --namespace=flux-system \
            --from-file=age.agekey=/dev/stdin


# Encrypts a secret in place
encrypt secret:
    @sops -i -e {{secret}}

# Decrypts a secret in place
decrypt secret:
    @sops -i -d {{secret}}

# Creates the SOPS-encrypted credentials for an app's role on the shared Postgres
# cluster: one basic-auth Secret "<app>-db" in ns databases (used by the
# DatabaseRole), which Reflector mirrors into the app's namespace (used by the
# app). The plaintext never touches disk.
# Usage: just db-secret <app> [cluster] [namespace]
db-secret app cluster="outerrim" namespace=app:
    #!/usr/bin/env bash
    set -euo pipefail
    out="kubernetes/apps/{{cluster}}/secrets/{{app}}-db.enc.yaml"
    if [[ -e "$out" ]]; then
        echo "error: $out already exists (delete it first to rotate)" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$out")"
    trap 'rm -f "$out.tmp"' EXIT
    pw="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 40)"
    kubectl create secret generic "{{app}}-db" --namespace databases \
        --type=kubernetes.io/basic-auth \
        --from-literal=username="{{app}}" \
        --from-literal=password="$pw" \
        --dry-run=client -o yaml \
    | kubectl annotate --local -f - -o yaml \
        reflector.v1.k8s.emberstack.com/reflection-allowed=true \
        reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces="{{namespace}}" \
        reflector.v1.k8s.emberstack.com/reflection-auto-enabled=true \
        reflector.v1.k8s.emberstack.com/reflection-auto-namespaces="{{namespace}}" \
    | sops encrypt --filename-override "$out" --input-type yaml --output-type yaml /dev/stdin > "$out.tmp"
    mv "$out.tmp" "$out"
    echo "wrote $out"
    echo "add 'secrets/{{app}}-db.enc.yaml' to kubernetes/apps/{{cluster}}/kustomization.yaml"

# pushes changes and reconciles flux
update:
    git push
    flux reconcile kustomization -n flux-system flux-system --with-source
    flux reconcile kustomization -n flux-system infrastructure --with-source
    flux reconcile kustomization -n flux-system platform --with-source
    flux reconcile kustomization -n flux-system apps --with-source

talosconfig:
    @mkdir -p ~/.talos
    topf talosconfig --topfconfig ./clusters/outer-rim/topf.yaml > ~/.talos/config

kubeconfig:
    @mkdir -p ~/.kube
    topf kubeconfig --topfconfig ./clusters/outer-rim/topf.yaml > ~/.kube/config
