# Hetzner Webhook

Hetzner webhook enables [cert manager](../../../base/cert-manager/README.md) to issue certificates using Hetzner DNS.

The following secret is necessary.

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: hetzner-dns-key
    namespace: cert-manager
type: Opaque
stringData:
    token: <TOKEN>
```

The cluster issuer represents a Certificate Authority (CA) and is able to generate signed certificates.
