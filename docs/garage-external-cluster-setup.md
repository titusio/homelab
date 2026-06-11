# Garage External Cluster Setup (TrueNAS)

Setting up a `GarageCluster` that acts as a gateway into a Garage instance running on TrueNAS requires two manual steps after initial deployment. The operator alone is not enough.

## What the operator does

- Creates the gateway pod and its per-node RPC LoadBalancer service (`<cluster>-0-rpc`)
- Configures `rpc_public_addr` in the gateway pod's `garage.toml` to point to the LB IP
- Applies the layout on the k8s side (adds TrueNAS nodes + gateway node)
- Keeps reporting `GatewayConnected: False / PartiallyConnected` — this is a known status issue; S3 still works

## Step 1 — Set `rpc_public_addr` on TrueNAS

TrueNAS runs Garage inside a Docker container. By default it advertises its internal Docker IP (e.g. `172.16.3.x`) as its RPC address. The k8s gateway can't reach this.

In the TrueNAS app config for the Garage instance, add a TOML override using the dot-prefix format:

```
.rpc_public_addr = "10.0.10.10:<rpc-port>"
```

The RPC port is usually `NodePort - 3` from the S3 port (e.g. S3 on `30190` → RPC on `30187`). Verify in the Garage web UI under the node info — it should show `10.0.10.10:XXXXX` after the change.

## Step 2 — ConnectClusterNodes

After `rpc_public_addr` is set, TrueNAS still doesn't know the k8s gateway's address. Call the Garage admin API on TrueNAS to introduce the gateway as a peer.

Get the gateway's node ID from the TrueNAS layout:

```sh
ADMIN_TOKEN=$(kubectl get secret -n object-storage <cluster>-secret -o jsonpath='{.data.adminToken}' | base64 -d)
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "http://10.0.10.10:<admin-port>/v1/layout" | jq '.roles[] | select(.tags[] | contains("tier:gateway"))'
```

Find the RPC LB IP:

```sh
kubectl get svc -n object-storage <cluster>-0-rpc -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then connect:

```sh
curl -s -X POST -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '["<gateway-node-id>@<rpc-lb-ip>:3901"]' \
  "http://10.0.10.10:<admin-port>/v1/connect"
```

Expected response: `[{"success": true, "error": null}]`

## Port reference (current deployments)

| Cluster       | Admin port | S3 port | Admin UI port | RPC port |
|---------------|-----------|---------|---------------|----------|
| scarif-depot  | 30290     | 30290   | 30286         | 30287    |
| scarif-vector | 30190     | 30190   | 30186         | 30187    |

## GatewayTombstones

After the initial layout is applied, the operator may report `GatewayTombstones: True` — a stale gateway entry from a prior layout version. With `autoApply: false` this is harmless; it does not affect S3 functionality. Avoid setting `autoApply: true` with an external cluster as the operator will loop adding/removing the gateway from the layout when `externalToGateway` is 0.
