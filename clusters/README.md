# Installing Talos on hetzner

Enter rescue mode.

```sh
curl -L --no-alpn -o talos.raw.xz "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.14.5/hcloud-amd64.raw.xz"

xz -d -c talos.raw.xz | dd of=/dev/sda bs=4M status=progress

sync

reboot
```

Then topf upgrade (not only apply since that won't pull the new image) - or just use the correct one in the command above...
