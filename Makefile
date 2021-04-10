
# Micro

# start micro server
microserve:
	micro server

# Login to micro server
micrologin:
	micro login --username admin --password micro

# -------------------------------------------------------------------------------------

# Running Micro as a container

## Start micro container, databases and broker. Finally login to micro in the container
microserveup:
	docker-compose up -d microserver
	docker-compose up -d pgdb timescaledb redis arangodb nats
	docker-compose up -d grafana
	sleep 20s
	docker exec microservercont  make  micrologin

## Start the whole application running in Docker
microup:
	docker-compose up -d microserver
	docker-compose up -d pgdb timescaledb redis arangodb nats
	docker-compose up -d grafana
	sleep 20s
	docker exec microservercont  make  micrologin
	docker exec microservercont  make  microstartsrvs
	docker-compose up web

## Stop application running in Docker
microdown:
	docker-compose down

# -------------------------------------------------------------------------------------

# Running Micro in K8s

## Run the whole application in Kubernetes, micro helm chart must already be installed
microk8sup:
	kubectl apply -f cicd/K8s/dbsAndBroker -n micro
	make micrologin
	make microstartsrvs
	kubectl apply -f cicd/K8s/monitoring -n micro
	make kpatchservices
	kubectl apply -f cicd/K8s/ingress -n micro
	kubectl apply -f cicd/K8s/web -n micro

## Stop the application running in K8s
microK8sdown:
	make microkillsrvs
	kubectl delete -f cicd/K8s/monitoring -n micro
	kubectl delete -f cicd/K8s/dbsAndBroker -n micro
	kubectl delete -f cicd/K8s/ingress -n micro
	kubectl delete -f cicd/K8s/web -n micro

# K8 Misc
 kapplyingress:
	kubectl apply -f cicd/K8s/ingress -n micro
 kapplyweb:
	kubectl apply -f cicd/K8s/web -n micro
 kdelete:
	kubectl delete -f $FOLDER -n micro
## Port froward to access micro running in K8s
microportfwd:
	kubectl port-forward svc/proxy -n micro 8081:443

# Patch microservices yaml to enable metric scraping
kpatchservices:
	kubectl patch svc audit -n micro --patch "$$(cat ./cicd/K8s/microservicesPatch/audit-service-patch.yaml)"
	kubectl patch svc customer -n micro --patch "$$(cat ./cicd/K8s/microservicesPatch/customer-service-patch.yaml)"
	kubectl patch svc product -n micro --patch "$$(cat ./cicd/K8s/microservicesPatch/product-service-patch.yaml)"
	kubectl patch svc promotion -n micro --patch "$$(cat ./cicd/K8s/microservicesPatch/promotion-service-patch.yaml)"
	kubectl patch svc user -n micro --patch "$$(cat ./cicd/K8s/microservicesPatch/user-service-patch.yaml)"


# -------------------------------------------------------------------------------------

# Run the whole application locally, micro server must already be running locally
microlocalup:
	#micro server
	docker-compose up -d pgdb timescaledb redis arangodb nats
	docker-compose up grafana
	#sleep 20s
	make  micrologin
	make  microstartsrvslocal
	docker-compose up web

microlocaldown:
	make microkillsrvs
	docker-compose down

# -------------------------------------------------------------------------------------

# Start individual services running in Docker or Kubernetes

## Start user service
microusersrv:
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/appuser,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name user  user/server

## Start audit service
microauditsrv:
	micro run --env_vars 'DB_CONNECT=postgresql://postgres:TestDB@home2@timescaledb/postgres,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats' --name audit audit/server

## Start product service
microproductsrv:
	micro run --env_vars 'DB_ADDRESS=arangodb:8529,DB_USER=productUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name product product/server

## Start customer service
microcustomersrv:
	micro run --env_vars 'DB_ADDRESS=arangodb:8529,DB_USER=customerUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name customer customer/server

## Start promotion service
micropromotionsrv:
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/postgres,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis,MICRO_STORE_ADDRESS=redis://:TestDB@home2@redis:6379' --name promotion  promotion/server

# -------------------------------------------------------------------------------------

# Start all services at once in Docker or K8s
microstartsrvs:
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/appuser,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name user  user/server
	sleep 12s
	micro run --env_vars 'DB_CONNECT=postgresql://postgres:TestDB@home2@timescaledb/postgres,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats' --name audit audit/server
	sleep 12s
	micro run --env_vars 'DB_ADDRESS=arangodb:8529,DB_USER=productUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name product product/server
	sleep 12s
	micro run --env_vars 'DB_ADDRESS=arangodb:8529,DB_USER=customerUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false' --name customer customer/server
	sleep 12s
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@pgdb/postgres,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@nats,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis,MICRO_STORE_ADDRESS=redis://:TestDB@home2@redis:6379' --name promotion  promotion/server

# -------------------------------------------------------------------------------------

# Delete all services
microkillsrvs:
	micro kill user
	micro kill audit
	micro kill product
	micro kill customer
	micro kill promotion

# -------------------------------------------------------------------------------------

# Delete all service test clients
microkillclis:
	micro kill usercli
	micro kill productcli
	micro kill customercli
	micro kill promotioncli

# -------------------------------------------------------------------------------------

# Start all the services running locally
microstartsrvslocal:
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@localhost/appuser?application_name=userSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost,DISABLE_AUDIT_RECORDS=false' --name user  user/server
	micro run --env_vars 'DB_CONNECT=postgresql://postgres:TestDB@home2@localhost:5433/postgres?application_name=auditSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost' --name audit audit/server
	micro run --env_vars 'DB_ADDRESS=localhost:8529,DB_USER=productUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost,DISABLE_AUDIT_RECORDS=false' --name product product/server
	micro run --env_vars 'DB_ADDRESS=localhost:8529,DB_USER=customerUser,DB_PASS=TestDB@home2,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost,DISABLE_AUDIT_RECORDS=false' --name customer customer/server
	micro run --env_vars 'POSTGRES_CONNECT=postgresql://postgres:TestDB@home2@localhost/postgres?application_name=promotionSrv,MICRO_BROKER=nats,MICRO_BROKER_ADDRESS=natsUser:TestDB@home2@localhost,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis,MICRO_STORE_ADDRESS=redis://:TestDB@home2@localhost:6379' --name promotion  promotion/server

# -------------------------------------------------------------------------------------
# Restart a service in place
microupdate:
	micro update $$SVCNAME

# DockerHub build and push images
hubpush:
	docker build -t $$SERVICE -f  $$FOLDER/Dockerfile .
	docker tag $$SERVICE bolbeck/gotempm_$$SERVICE
	docker push bolbeck/gotempm_$$SERVICE

hubpushcontext:
	docker build -t $$SERVICE -f  ./$$FOLDER/Dockerfile ./$$FOLDER
	docker tag $$SERVICE bolbeck/gotempm_$$SERVICE
	docker push bolbeck/gotempm_$$SERVICE

# -------------------------------------------------------------------------------------
# Web App

## Start directly (dev)
runweb:
	npm run dev

## Docker
docbuildweb:
	docker build -t goTempMweb -f ./web/Dockerfile ./web
docrunweb:
	docker run -p 3000:3000 --name goTempMwebcont goTempMweb

## Docker-compose
composeupweb:
	docker-compose up web


# -------------------------------------------------------------------------------------

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

# -------------------------------------------------------------------------------------

# Curl services

## Services running locally
promoviaapigateway:
	curl --location --request POST 'http://localhost:8080/promotion/promotionSrv/getPromotions' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VyIjp7ImlkIjoyMzQzNzI1MzkxMjkxNjE4MzA1LCJjb21wYW55IjoiRHVjayBJbmMuIn0sImV4cCI6MTU5NzMzNTMzNywiaWF0IjoxNTk3MjQ4OTM3LCJpc3MiOiJnb1RlbXAudXNlcnNydiJ9.QWAvvoXQHv_Cf48PTrjK9uRvrdEblNvFOxQWjNcX79U' \
    --data-raw '{"name":"Promo1", "customerId": "ducksrus"}'

# Call service using running behind the ingress in K8s
authviaapigateway:
	curl --location --request POST 'http://goTempM.tst/user/userSrv/auth' \
	--header 'Content-Type: application/json' \
	--data-raw '{"pwd":"1234","email":"duck@mymail.com"}'


# -------------------------------------------------------------------------------------

# Run Micro in K8s with Vault for service secret management

# ---- Setup Vault ------

# init secrets and K8s auth in Vault
vkubinit:
	kubectl cp vault/scripts vault-0:/vault/file/
	kubectl exec vault-0 -- /vault/file/scripts/setup.sh $$VAULT_TOKEN

# Populate secrets, create roles and policies
vkubsetup:
	kubectl cp vault/policies vault-0:/vault/file/
	kubectl cp vault/scripts vault-0:/vault/file/
	kubectl exec vault-0 -- /vault/file/scripts/allServices.sh  $$VAULT_TOKEN

# ---- Integrate Vault with App ------

# Apply patches to the services' deployments so they are visible to the Vault Agent
# This is done after the pods are already deployed
vkubpatchdeploy:
	kubectl apply -f cicd/K8s/vault/serviceAccount -n micro
	kubectl patch deployment audit-latest -n micro --patch "$$(cat cicd/K8s/vault/patch/auditsrv-deployment-patch.yaml)"
	kubectl patch deployment customer-latest -n micro --patch "$$(cat cicd/K8s/vault/patch/customersrv-deployment-patch.yaml)"
	kubectl patch deployment product-latest -n micro --patch "$$(cat cicd/K8s/vault/patch/productsrv-deployment-patch.yaml)"
	kubectl patch deployment user-latest -n micro --patch "$$(cat cicd/K8s/vault/patch/usersrv-deployment-patch.yaml)"
	kubectl patch deployment promotion-latest -n micro --patch "$$(cat cicd/K8s/vault/patch/promotionsrv-deployment-patch.yaml)"

# Remove service accounts used to integrate with Vault
# This is done after application is brought down
vkubdelserviceaccounts:
	kubectl delete -f cicd/K8s/vault/serviceAccount -n micro

# ------ Remove setup from Vault -------

# Remove secrets, create roles and policies
vkubteardown:
	kubectl cp vault/scripts vault-0:/vault/file/
	kubectl exec vault-0 -- /vault/file/scripts/deleteAllSrv.sh $$VAULT_TOKEN
	make vkubcleancontainer

# Remove secret engine and K8s auth in Vault
vkubsetupdelete:
	kubectl cp vault/scripts vault-0:/vault/file/
	kubectl exec vault-0 -- /vault/file/scripts/deleteSetup.sh  $$VAULT_TOKEN
	make vkubcleancontainer


# ---- Vault Misc --------

# Unseal Vault on startup
vkubunseal:
	kubectl exec -ti vault-0 -- vault operator unseal $$KEY
# Enable Vault UI port
vkubui:
	kubectl port-forward vault-0 8100:8200


# Commands to test services with Vault secrets and no connections in env vars
vtestnosecrets:
	micro run --env_vars 'MICRO_BROKER=nats,DISABLE_AUDIT_RECORDS=false' --name user  user/server
	micro run --env_vars 'MICRO_BROKER=nats' --name audit audit/server
	micro run --env_vars 'MICRO_BROKER=nats,DISABLE_AUDIT_RECORDS=false' --name product product/server
	micro run --env_vars 'MICRO_BROKER=nats,DISABLE_AUDIT_RECORDS=false' --name customer customer/server
	micro run --env_vars 'MICRO_BROKER=nats,DISABLE_AUDIT_RECORDS=false,MICRO_STORE=redis' --name promotion  promotion/server

# Clean scripts and policies in Vault container
vkubcleancontainer:
	kubectl exec vault-0 -- rm -rf /vault/file/scripts/
	kubectl exec vault-0 -- rm -rf /vault/file/policies/
