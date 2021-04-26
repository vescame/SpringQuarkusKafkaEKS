SHELL = /bin/sh

namespace=quarkus-cqrs-demo

.SILENT: help
.PHONY: help
help:
	echo "usage: make RULES [args...]"
	echo ""
	echo "Main RULES:"
	echo ""
	echo "build			- build up transaction and balance apps"
	echo "publish			- publish transaction and balance images"
	echo "deploy			- deploy all"
	echo "undeploy		- undeploy all"
	echo ""
	echo "pods			- list pods"
	echo "all			- list all resources from quarku-cqrs-demo namespace"
	echo "exec pod=arg		- execute bash inside a pod"
	echo "desc res=arg		- describe resources"
	echo "get res=arg		- get some resources"
	echo "logs pod=arg		- get pod logs"
	echo ""

build-transaction:
	mvn -f ./transaction-service package -Pnative \
		-Dquarkus.native.container-build=true
	docker build -f ./transaction-service/src/main/docker/Dockerfile.native \
		-t vescame/quarkus-balance-service:v1 \
		./transaction-service

build-balance:
	mvn -f ./balance-service package -Pnative \
		-Dquarkus.native.container-build=true
	docker build -f ./balance-service/src/main/docker/Dockerfile.native \
		-t vescame/quarkus-transaction-service:v1 \
		./balance-service

build: build-transaction build-balance

publish: build
	docker login
	docker push vescame/quarkus-transaction-service:v1
	docker push vescame/quarkus-balance-service:v1

validate:
	if [ -z "$${AWS_PROFILE}" ]; then echo 'Atribua a env var AWS_PROFILE' ; \
		exit 1 ; fi

deploy-namespace: validate
	kubectl apply -f kubefiles/namespace.yml

undeploy-namespace: validate
	kubectl delete -f kubefiles/namespace.yml

deploy-ingress: validate
	kubectl apply -f kubefiles/namespace.yml

undeploy-ingress: validate
	kubectl delete -f kubefiles/namespace.yml

deploy-transaction: validate
	kubectl apply -f transaction-service/src/main/kubefiles

undeploy-transaction: validate
	kubectl delete -f transaction-service/src/main/kubefiles

deploy-balance: validate
	kubectl apply -f balance-service/src/main/kubefiles

undeploy-balance: validate
	kubectl delete -f balance-service/src/main/kubefiles

deploy-broker: validate
	kubectl apply -f kubefiles/broker/

undeploy-broker: validate
	kubectl delete -f kubefiles/broker/

deploy-db: validate
	kubectl apply -f kubefiles/postgres/

undeploy-db: validate
	kubectl delete -f kubefiles/postgres/

apply: validate
	kubectl apply -f $(f)

deploy: deploy-namespace deploy-broker deploy-postgres deploy-transaction \
	deploy-balance deploy-ingress

undeploy: undeploy-transaction undeploy-balance undeploy-broker \
	undeploy-db undeploy-ingress

del: validate
	kubectl delete -f $(f)

exec:
	kubectl -n $(namespace) exec -it $(pod) -- /bin/bash

logs:
	kubectl -n $(namespace) logs $(pod)

desc:
	kubectl -n $(namespace) describe $(res)

pods:
	kubectl -n $(namespace) get pods

get:
	kubectl -n $(namespace) get $(res)

all:
	kubectl -n $(namespace) get all

