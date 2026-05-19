# Creates the Flux SOPS secret inside the cluster. 
create-sops-secret:
    @sops -d ./secrets/core-worlds.enc.age | \
        kubectl create secret generic sops-age \
            --namespace=flux-system \
            --from-file=age.agekey=/dev/stdin


# Encrypts a secret in place
encrypt secret:
    @sops -i -e {{secret}}

# Decrypts a secret in place
decrypt secret:
    @sops -i -d {{secret}}
