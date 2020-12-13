/*
Package globalCache provieds cache to be used in the services. Helps reduce the number of times
we need to hit the DB. It is composed of the following files:
- redis: Based on the old deprecated go-micro redis plug-in, enables redis to be used as a Micro store. This store is then used as KV cache for services.
*/
package globalCache
