
#DockerHub
hubpush:
	docker build -t $$SERVICE -f  $$FOLDER/Dockerfile .
	docker tag $$SERVICE bolbeck/goTempM_$$SERVICE
	docker push bolbeck/goTempM_$$SERVICE

hubpushcontext:
	docker build -t $$SERVICE -f  ./$$FOLDER/Dockerfile ./$$FOLDER
	docker tag $$SERVICE bolbeck/goTempM_$$SERVICE
	docker push bolbeck/goTempM_$$SERVICE


# Web App

# Directly (dev)
	npm run dev

# Docker
docbuildweb:
	docker build -t goTempMweb -f ./web/Dockerfile ./web
docrunweb:
	docker run -p 3000:3000 --name goTempMwebcont goTempMweb

#Docker-compose
composeupweb:
	docker-compose up web


# Compile proto files
genpromotionproto:
	protoc --proto_path=$$GOPATH/src:. --micro_out=source_relative:.. --go_out=. --go_opt=paths=source_relative promotion/proto/promotion.proto
genuserproto:
	protoc --proto_path=$$GOPATH/src:. --micro_out=source_relative:.. --go_out=. --go_opt=paths=source_relative user/proto/user.proto
gencustomerproto:
	protoc --proto_path=$$GOPATH/src:. --micro_out=source_relative:.. --go_out=. --go_opt=paths=source_relative customer/proto/customer.proto
genproductproto:
	protoc --proto_path=$$GOPATH/src:. --micro_out=source_relative:.. --go_out=. --go_opt=paths=source_relative product/proto/product.proto
genstandardFieldsproto:
	protoc --proto_path=$$GOPATH/src:. --micro_out=source_relative:.. --go_out=. --go_opt=paths=source_relative globalProtos/standardFields.proto

# Call service through the micro gateway
promoviaapigateway:
	curl --location --request POST 'http://localhost:8080/goTempM.api.promotion/promotionSrv/getPromotions' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VyIjp7ImlkIjoyMzQzNzI1MzkxMjkxNjE4MzA1LCJjb21wYW55IjoiRHVjayBJbmMuIn0sImV4cCI6MTU5NzMzNTMzNywiaWF0IjoxNTk3MjQ4OTM3LCJpc3MiOiJnb1RlbXAudXNlcnNydiJ9.QWAvvoXQHv_Cf48PTrjK9uRvrdEblNvFOxQWjNcX79U' \
    --data-raw '{"name":"Promo1", "customerId": "ducksrus"}'

# Call service using the micro gateway running behind the ingress in K8s
#authviaapigateway:
#	curl --location --request POST 'http://goTempM.tst/goTempM.api.user/userSrv/auth' \
#	--header 'Content-Type: application/json' \
#	--data-raw '{"pwd":"1234","email":"duck@mymail.com"}'

# K8s
#
#startkub:
#	kubectl apply -f cicd/K8s/services
#	kubectl apply -f cicd/K8s/web
#	kubectl apply -f cicd/K8s/ingress
#stopkub:
#	kubectl delete -f cicd/K8s/ingress
#	kubectl delete -f cicd/K8s/web
#	kubectl delete -f cicd/K8s/services


#kapplyingress:
#	kubectl apply -f cicd/K8s/ingress
#kapplyservices:
#	kubectl apply -f cicd/K8s/services
#kapplyclients:
#	kubectl apply -f cicd/K8s/clients
#kapplyweb:
#	kubectl apply -f cicd/K8s/web
#kdelete:
#	kubectl delete -f $FOLDER
#
#kstartSubset:
#	kubectl apply $(ls cicd/K8s/services/audit*.yaml | awk ' { print " -f " $1 } ')


# Misc

#encode:
#	echo -n 'data' | base64
#decode:
#	echo -n ZGF0YQ== | base64 -d

# Micro

# start micro server
microserve:
	micro server

# Login to micro server
micrologin:
	micro login --username admin --password micro

# Start micro container, databases and broker. Finally login to micro in the container
microserveup:
	docker-compose up -d microserver
	docker-compose up -d pgdb timescaledb redis arangodb nats
	sleep 20s
	docker exec microservercont  make  micrologin

# Start user service
microusersrv:
	micro run --env_vars POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/appuser?application_name=userSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name usersrv  user/server

# Start audit service
microauditsrv:
	micro run --env_vars DB_CONNECT=postgresql://postgres:TestDB@home2@timescaledb/postgres?application_name=auditSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost --name auditsrv audit/server

# Start product service
microproductsrv:
	micro run --env_vars DB_ADDRESS=arangodb:8529,DB_USER=productUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name productsrv product/server

# Start customer service
microcustomersrv:
	micro run --env_vars DB_ADDRESS=arangodb:8529,DB_USER=customerUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name customersrv customer/server

# Start promotion service
micropromotionsrv:
	micro run --env_vars POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/postgres?application_name=promotionSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis,MICRO_STORE_ADDRESS=redis://:TestDB@home2@redis:6379 --name promotionsrv  promotion/server

# Start all services at once
microstartsrvs:
	micro run --env_vars POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/appuser?application_name=userSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name usersrv  user/server
	sleep 12s
	micro run --env_vars DB_CONNECT=postgresql://postgres:TestDB@home2@timescaledb/postgres?application_name=auditSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost --name auditsrv audit/server
	sleep 12s
	micro run --env_vars DB_ADDRESS=arangodb:8529,DB_USER=productUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name productsrv product/server
	sleep 12s
	micro run --env_vars DB_ADDRESS=arangodb:8529,DB_USER=customerUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false --name customersrv customer/server
	sleep 12s
	micro run --env_vars POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/postgres?application_name=promotionSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis,MICRO_STORE_ADDRESS=redis://:TestDB@home2@redis:6379 --name promotionsrv  promotion/server

# Start the whole application running in containers
microup:
	docker-compose up -d microserver
	docker-compose up -d pgdb timescaledb redis arangodb nats
	sleep 20s
	docker exec microservercont  make  micrologin
	docker exec microservercont  make  microstartsrvs
	docker-compose up web

