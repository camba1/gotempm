#!/bin/sh

# Check if we got a vault token to be able to login
if [ "$#" -ne 1 ]
  then
    echo "No vault token supplied" >&2
    exit 1
fi

echo "Creating usersrv artifacts...."

# Export token used to login to vault
export VAULT_TOKEN=$1

# Create key value pair secrets
 vault kv put gotempmkv/database/postgresql/usersrv username="postgres" password="TestDB@home2" application_name="userSrv" server="pgdb" dbname="appuser"

 vault kv put gotempmkv/broker/nats/usersrv username="natsUser" password="TestDB@home2" server="nats"


# Create Vault Policy
vault policy write gotempm-usersrv /vault/file/policies/usersrv.hcl


# Create Vault K8s role to associate service account to the appropriate policy
vault write auth/kubernetes/role/gotempm-usersrv \
    bound_service_account_names=gotempm-usersrv \
    bound_service_account_namespaces=micro \
    policies=gotempm-usersrv \
    ttl=24h