// Create policies to allow the vault agent running in K8s to read the secrets

path "gotempmkv/data/database/postgresql/usersrv" {
  capabilities = ["read"]
}

path "gotempmkv/data/broker/nats/usersrv" {
  capabilities = ["read"]
}