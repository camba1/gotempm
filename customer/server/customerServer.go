package main

import (
	"context"
	"fmt"
	adb "github.com/arangodb/go-driver"
	//"github.com/micro/go-micro/v2/service"
	//"github.com/micro/go-micro/v2"
	//"github.com/micro/micro/v3"
	//"github.com/micro/go-micro/v2/client"
	//"github.com/micro/go-micro/v2/metadata"
	//"github.com/micro/go-micro/v2/server"

	microServ "github.com/micro/micro/v3/service"
	microBroker "github.com/micro/micro/v3/service/broker"
	"github.com/micro/micro/v3/service/client"
	"github.com/micro/micro/v3/service/context/metadata"
	"github.com/micro/micro/v3/service/server"

	"goTempM/customer/proto"
	"goTempM/customer/server/statements"
	"goTempM/globalUtils"
	"goTempM/globalerrors"
	pb "goTempM/user/proto"
	userSrv "goTempM/user/proto"
	"log"
	"os"
	"strings"
)

const (
	// serviceName service identifier
	//serviceName = "goTempM.api.customer"
	serviceName = "customer"
	// serviceNameUser service identifier for user service
	//serviceNameUser = "goTempM.api.user"
	serviceNameUser = "user"
)

//DB related constants
const (
	// dbName Name of the DB hosting the data
	dbName = "customer"
	// dbAddressEnvVarName Name of Environment variable that contains the address to the DB
	dbAddressEnvVarName = "DB_ADDRESS"
	// dbUserEnvVarName Name of Environment variable that contains the database username
	dbUserEnvVarName = "DB_USER"
	// dbPassEnvVarName Name of Environment variable that contains the database password
	dbPassEnvVarName = "DB_PASS"
)

// Other constants
const (
	DisableAuditRecordsEnvVarName = "DISABLE_AUDIT_RECORDS"
)

// conn Database connection
var conn adb.Database

// custErr Holds service specific errors
var custErr statements.CustErr

// glErr Holds the service global errors that are shared cross services
var glErr globalerrors.SrvError

// mb Broker instance to send/receive message from pub/sub system
var mb globalUtils.MyBroker

// glDisableAuditRecords Allows all insert,update,delete records to be sent out to the broker for forwarding to
var glDisableAuditRecords = false

// customer Main entry point for customer related services
type customer struct{}

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
		//token := meta["Token"]

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

// getDBConnString Get the connection string to the DB
func getDBConnString() *globalUtils.DbConnParams {
	addressString := os.Getenv(dbAddressEnvVarName)
	if addressString == "" {
		log.Fatalf(glErr.DbNoConnectionString(dbAddressEnvVarName))
	}
	userNameString := os.Getenv(dbUserEnvVarName)
	if userNameString == "" {
		log.Fatalf(glErr.DbNoConnectionString(dbUserEnvVarName))
	}
	passString := os.Getenv(dbPassEnvVarName)
	if passString == "" {
		log.Fatalf(glErr.DbNoConnectionString(dbPassEnvVarName))
	}
	return &globalUtils.DbConnParams{
		Address:  addressString,
		Username: userNameString,
		Password: passString,
	}
}

// connectToDB Call the Util pgxDBConnect to connect to the database. Service will try to connect a few times
//before giving up and throwing an error
func connectToDB() adb.Database {
	var dbConnect globalUtils.ArangoConnect
	db, err := dbConnect.ConnectToDBWithRetry(dbName, getDBConnString())
	if err != nil {
		log.Fatalf(glErr.DbNoConnection(dbName, err))
	}
	return db
}

func loadConfig() {
	//conf, err := config.NewConfig()
	//if err != nil {
	//	log.Fatalf("Unable to create new application configuration object. Err: %v\n", err)
	//	//log.Fatal(err)
	//}
	//defer conf.Close()
	//
	//src := env.NewSource()
	//
	//err = conf.Load(src)
	////ws, err := src.Read()
	//if err != nil {
	//	log.Fatalf("Unable to load application configuration object. Err: %v\n", err)
	//	//log.Fatal(err)
	//}
	//test := conf.Map()
	////log.Printf("conf %v\n", ws.Data)
	//
	//log.Printf("conf map %v\n", test)

	audits := os.Getenv(DisableAuditRecordsEnvVarName)
	if audits == "true" {
		glDisableAuditRecords = true
	} else {
		glDisableAuditRecords = false
	}
}

func main() {

	// setup metrics collector
	metricsWrapper := newMetricsWrapper()

	// instantiate service
	//service := micro.NewService(
	//	micro.Name(serviceName),
	//	micro.WrapHandler(AuthWrapper),
	//)

	service := microServ.New(
		microServ.Name(serviceName),
		microServ.WrapHandler(AuthWrapper),
		microServ.WrapHandler(metricsWrapper),
	)

	service.Init()
	err := proto.RegisterCustomerSrvHandler(service.Server(), new(customer))
	if err != nil {
		log.Fatalf(glErr.SrvNoHandler(err))
	}

	// Load configuration
	loadConfig()

	// Connect to DB
	conn = connectToDB()

	// defer conn.Close(context.Background())

	// setup the nats broker
	//mb.Br = service.Options().Broker
	mb.Br = microBroker.DefaultBroker
	defer mb.Br.Disconnect()

	// Initialize http server for metrics export
	go runHttp()

	// Run Service
	err = service.Run()
	if err != nil {
		log.Fatalf(glErr.SrvNoStart(serviceName, err))
	}
}
