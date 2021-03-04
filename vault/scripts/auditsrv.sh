#!/bin/sh

# Check if we got a vault token to be able to login
if [ "$#" -ne 1 ]
  then
    echo "No vault token supplied" >&2
    exit 1
fi

echo "Creating auditsrv artifacts...."

# Export token used to login to vault
export VAULT_TOKEN=$1

# Create key value pair secrets
vault kv put gotempmkv/database/timescaledb/auditsrv username="postgres" password="TestDB@home2" application_name="auditSrv" server="timescaledb" dbname="postgres"

vault kv put gotempmkv/broker/nats/auditsrv username="natsUser" password="TestDB@home2" server="nats"

# Create Vault Policy
vault policy write gotempm-auditsrv /vault/file/policies/auditsrv.hcl


# Create Vault K8s role to associate service account to the appropriate policy
vault write auth/kubernetes/role/gotempm-auditsrv \
    bound_service_account_names=gotempm-auditsrv \
    bound_service_account_namespaces=micro \
    policies=gotempm-auditsrv \
    ttl=24h