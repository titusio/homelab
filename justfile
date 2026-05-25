# Creates the Flux SOPS secret inside the cluster. 
create-sops-secret:
    @sops -d ./secrets/core-worlds.enc.age | \
        kubectl create secret generic sops-age \
            --namespace=flux-system \
            --from-file=age.agekey=/dev/stdin


# Issues a Matrix compatibility token for a MAS bot account
mas-bot-token username:
    @kubectl exec -n chats deployment/synapse-matrix-authentication-service -- mas-cli manage issue-compatibility-token {{username}} 2>&1 | grep -oP 'mct_\S+'

# Encrypts a secret in place
encrypt secret:
    @sops -i -e {{secret}}

# Decrypts a secret in place
decrypt secret:
    @sops -i -d {{secret}}
