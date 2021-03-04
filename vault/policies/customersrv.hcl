// Create policies to allow the vault agent running in K8s to read the secrets

path "gotempmkv/data/database/arangodb/customersrv" {
  capabilities = ["read"]
}

path "gotempmkv/data/broker/nats/customersrv" {
  capabilities = ["read"]
}
