#!/bin/sh

# Check if we got a vault token to be able to login
if [ "$#" -ne 1 ]
  then
    echo "No service name supplied" >&2
    exit 1
fi

# Delete role
vault delete auth/kubernetes/role/gotempm-"$1"
# Delete policy
vault policy delete gotempm-"$1"

#Delete secrets (all versions and metadata)
vault kv metadata delete gotempmkv/database/postgresql/"$1"
vault kv metadata delete gotempmkv/database/redis/"$1"
vault kv metadata delete gotempmkv/database/arangodb/"$1"
vault kv metadata delete gotempmkv/database/timescaledb/"$1"
vault kv metadata delete gotempmkv/broker/nats/"$1"