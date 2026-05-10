# Creates the Flux SOPS secret inside the cluster. 
create-sops-secret:
    @sops -d ./secrets/core-worlds.enc.age | \
        kubectl create secret generic sops-age \
            --namespace=flux-system \
            --from-file=age.agekey=/dev/stdin
