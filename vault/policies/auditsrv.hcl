// Create policies to allow the vault agent running in K8s to read the secrets

path "gotempmkv/data/database/timescaledb/auditsrv"  {
  capabilities = ["read"]
}

path "gotempmkv/data/broker/nats/auditsrv" {
  capabilities = ["read"]
}