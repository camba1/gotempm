package main

import (
	"context"
	"fmt"
	"github.com/jackc/pgx/v4"
	"goTempM/globalCache"

	//"github.com/micro/go-micro/v2/service"
	//"github.com/micro/go-micro/v2"
	//"github.com/micro/go-micro/v2/client"
	//"github.com/micro/go-micro/v2/metadata"
	//"github.com/micro/go-micro/v2/server"

	microServ "github.com/micro/micro/v3/service"
	microBroker "github.com/micro/micro/v3/service/broker"
	"github.com/micro/micro/v3/service/client"
	"github.com/micro/micro/v3/service/context/metadata"
	"github.com/micro/micro/v3/service/server"
	microStore "github.com/micro/micro/v3/service/store"

	"goTempM/globalUtils"
	"goTempM/promotion/proto"
	pb "goTempM/user/proto"
	userSrv "goTempM/user/proto"
	"log"
	"os"
	"strings"
)

const (
	// serviceName service identifier
	//serviceName = "goTempM.api.promotion"
	serviceName = "promotion"
	// serviceNameUser service identifier for user service
	//serviceNameUser = "goTempM.api.user"
	serviceNameUser = "user"
	// serviceNameCustomer service identifier for customer service
	//serviceNameCustomer = "goTempM.api.customer"
	serviceNameCustomer = "customer"
)

const (
	// dbName Name of the DB hosting the data
	dbName = "postgres"
	// dbConStrEnvVarName Name of Environment variable that contains connection string to DB
	dbConStrEnvVarName = "POSTGRES_CONNECT"
	// cacheAddressEnvVarName Name of the environment variable that holds connection string to cache engine
	cacheAddressEnvVarName = "MICRO_STORE_ADDRESS"
)

// Other constants
const (
	DisableAuditRecordsEnvVarName = "DISABLE_AUDIT_RECORDS"
)

// conn Database connection
var conn *pgx.Conn

// glDisableAuditRecords allows all insert,update,delete records to be sent out to the broker for forwarding to
var glDisableAuditRecords = false

// glCacheAddress
var glCacheAddress string

// glCache Store to hold cached values
var glCache globalUtils.Cache

// AuthWrapper defines the authentication middleware
func AuthWrapper(fn server.HandlerFunc) server.HandlerFunc {
	return func(ctx context.Context, req server.Request, resp interface{}) error {
		meta, ok := metadata.FromContext(ctx)
		if !ok {
			return fmt.Errorf(glErr.AuthNoMetaData(req.Endpoint()))
		}

		auth, ok := meta["Authorization"]
		if !ok {
			return fmt.Errorf(glErr.AuthNilToken())
		}
		authSplit := strings.SplitAfter(auth, " ")
		if len(authSplit) != 2 {
			return fmt.Errorf(glErr.AuthNilToken())
		}
		token := authSplit[1]
		// token := meta["Token"]

		log.Printf("endpoint: %v", req.Endpoint())

		userClient := userSrv.NewUserSrvService(serviceNameUser, client.DefaultClient)
		outToken, err := userClient.ValidateToken(ctx, &pb.Token{Token: token})
		if err != nil {
			return err
		}
		if outToken.Valid != true {
			return fmt.Errorf(glErr.AuthInvalidToken())
		}

		if outToken.EUid == "" {
			return fmt.Errorf("unable to get user id from token for endpoint %v\n", req.Endpoint())
		}
		ctx2 := metadata.Set(ctx, "userid", outToken.EUid)

		return fn(ctx2, req, resp)
	}
}

// getDBConnString gets the connection string to the DB
func getDBConnString() string {
	connString := os.Getenv(dbConStrEnvVarName)
	if connString == "" {
		log.Fatalf(glErr.DbNoConnectionString(dbConStrEnvVarName))
	}
	return connString
}

// connectToDB call the Util pgxDBConnect to connect to the database. Service will try to connect a few times
// before giving up and throwing an error
func connectToDB() *pgx.Conn {
	var pgxConnect globalUtils.PgxDBConnect
	dbConn, err := pgxConnect.ConnectToDBWithRetry(dbName, getDBConnString())
	if err != nil {
		log.Fatalf(glErr.DbNoConnection(dbName, err))
	}
	return dbConn
}

func loadConfig() {
	// conf, err := config.NewConfig()
	// if err != nil {
	// 	log.Fatalf("Unable to create new application configuration object. Err: %v\n", err)
	// 	// log.Fatal(err)
	// }
	// defer conf.Close()
	//
	// src := env.NewSource()
	//
	// err = conf.Load(src)
	// // ws, err := src.Read()
	// if err != nil {
	// 	log.Fatalf("Unable to load application configuration object. Err: %v\n", err)
	// 	// log.Fatal(err)
	// }
	// test := conf.Map()
	// // log.Printf("conf %v\n", ws.Data)
	//
	// log.Printf("conf map %v\n", test)

	audits := os.Getenv(DisableAuditRecordsEnvVarName)
	if audits == "true" {
		glDisableAuditRecords = true
	} else {
		glDisableAuditRecords = false
	}

	glCacheAddress = os.Getenv(cacheAddressEnvVarName)

}

func main() {

	// Load configuration
	loadConfig()

	// setup metrics collector
	metricsWrapper := newMetricsWrapper()

	service := microServ.New(
		microServ.Name(serviceName),
		microServ.WrapHandler(AuthWrapper),
		microServ.WrapHandler(metricsWrapper),
	)

	// initialize plugins (this is just needed for stores)
	//initPlugins()

	if glCacheAddress == "" {
		log.Fatal(glErr.CacheEnvVarAddressNotSet())
	}
	microStore.DefaultStore = globalCache.NewStore(microStore.Nodes(glCacheAddress))

	service.Init()
	err := proto.RegisterPromotionSrvHandler(service.Server(), new(Promotion))
	if err != nil {
		log.Fatalf(glErr.SrvNoHandler(err))
	}

	// init the cache store
	//glCache.Store = service.Options().Store

	glCache.Store = microStore.DefaultStore
	glCache.SetDatabaseName(serviceName)
	defer glCache.Store.Close()

	// Connect to DB
	conn = connectToDB()
	defer conn.Close(context.Background())

	// setup the nats broker
	//mb.Br = service.Options().Broker
	mb.Br = microBroker.DefaultBroker
	defer mb.Br.Disconnect()

	// Initialize http server for metrics export
	go runHttp()

	//  Run Service
	if err := service.Run(); err != nil {
		log.Fatalf(glErr.SrvNoStart(serviceName, err))
	}

}
