// Create policies to allow the vault agent running in K8s to read the secrets

path "gotempmkv/data/database/postgresql/promotionsrv" {
  capabilities = ["read"]
}

path "gotempmkv/data/broker/nats/promotionsrv" {
  capabilities = ["read"]
}

path "gotempmkv/data/database/redis/promotionsrv" {
  capabilities = ["read"]
}