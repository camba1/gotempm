#!/bin/sh

# Check if we got a vault token to be able to login
if [ "$#" -ne 1 ]
  then
    echo "No vault token supplied" >&2
    exit 1
fi

echo "Creating productsrv artifacts...."

# Export token used to login to vault
export VAULT_TOKEN=$1

# Create key value pair secrets
vault kv put gotempmkv/database/arangodb/productsrv username="productUser" password="TestDB@home2" server="arangodb:8529"

vault kv put gotempmkv/broker/nats/productsrv username="natsUser" password="TestDB@home2" server="nats"

# Create Vault Policy
vault policy write gotempm-productsrv /vault/file/policies/productsrv.hcl


# Create Vault K8s role to associate service account to the appropriate policy
vault write auth/kubernetes/role/gotempm-productsrv \
    bound_service_account_names=gotempm-productsrv \
    bound_service_account_namespaces=micro \
    policies=gotempm-productsrv \
    ttl=24h