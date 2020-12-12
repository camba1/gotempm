package globalCache

import (
	"context"
	"fmt"
	"github.com/go-redis/redis/v8"
	"github.com/micro/micro/v3/service/logger"
	"github.com/micro/micro/v3/service/store"
)

var ctx = context.Background()

type rkv struct {
	opts   store.StoreOptions
	Client *redis.Client
}

func (r *rkv) Init(opts ...store.StoreOption) error {
	for _, o := range opts {
		o(&r.opts)
	}

	return r.configure()
}

func (r *rkv) Close() error {
	return r.Client.Close()
}

func (r *rkv) Read(key string, opts ...store.ReadOption) ([]*store.Record, error) {
	options := store.ReadOptions{}
	options.Table = r.opts.Table

	for _, o := range opts {
		o(&options)
	}

	var keys []string

	rkey := fmt.Sprintf("%s%s", options.Table, key)
	// Handle Prefix
	// TODO suffix
	if options.Prefix {
		prefixKey := fmt.Sprintf("%s*", rkey)
		fkeys, err := r.Client.Keys(ctx, prefixKey).Result()
		if err != nil {
			return nil, err
		}
		// TODO Limit Offset

		keys = append(keys, fkeys...)

	} else {
		keys = []string{rkey}
	}

	records := make([]*store.Record, 0, len(keys))

	for _, rkey = range keys {
		val, err := r.Client.Get(ctx, rkey).Bytes()

		if err != nil && err == redis.Nil {
			return nil, store.ErrNotFound
		} else if err != nil {
			return nil, err
		}

		if val == nil {
			return nil, store.ErrNotFound
		}

		d, err := r.Client.TTL(ctx, rkey).Result()
		if err != nil {
			return nil, err
		}

		records = append(records, &store.Record{
			Key:    key,
			Value:  val,
			Expiry: d,
		})
	}

	return records, nil
}

func (r *rkv) Delete(key string, opts ...store.DeleteOption) error {
	options := store.DeleteOptions{}
	options.Table = r.opts.Table

	for _, o := range opts {
		o(&options)
	}

	rkey := fmt.Sprintf("%s%s", options.Table, key)
	return r.Client.Del(ctx, rkey).Err()
}

func (r *rkv) Write(record *store.Record, opts ...store.WriteOption) error {
	options := store.WriteOptions{}
	options.Table = r.opts.Table

	for _, o := range opts {
		o(&options)
	}

	rkey := fmt.Sprintf("%s%s", options.Table, record.Key)
	return r.Client.Set(ctx, rkey, record.Value, record.Expiry).Err()
}

func (r *rkv) List(opts ...store.ListOption) ([]string, error) {
	options := store.ListOptions{}
	options.Table = r.opts.Table

	for _, o := range opts {
		o(&options)
	}

	keys, err := r.Client.Keys(ctx, "*").Result()
	if err != nil {
		return nil, err
	}

	return keys, nil
}

func (r *rkv) Options() store.StoreOptions {
	return r.opts
}

func (r *rkv) String() string {
	return "redis"
}

func NewStore(opts ...store.StoreOption) store.Store {
	var options store.StoreOptions
	for _, o := range opts {
		o(&options)
	}

	s := new(rkv)
	s.opts = options

	if err := s.configure(); err != nil {
		logger.Fatal(err)
	}

	return s
}

func (r *rkv) configure() error {
	var redisOptions *redis.Options
	nodes := r.opts.Nodes
	if len(nodes) == 0 {
		nodes = []string{"redis://127.0.0.1:6379"}
	}

	redisOptions, err := redis.ParseURL(nodes[0])
	if err != nil {
		//Backwards compatibility
		redisOptions = &redis.Options{
			Addr:     nodes[0],
			Password: "", // no password set
			DB:       0,  // use default DB
		}
	}

	r.Client = redis.NewClient(redisOptions)

	return nil
}
