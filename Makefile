NAME = akisys/mongodb-cluster
VERSION = 3.4

.PHONY: all build run

all: build

build:
	docker build -t $(NAME):$(VERSION) --rm .

deploy: build
	docker push $(NAME):$(VERSION)

service-compose: build
	docker-compose up

compose-shardcfg: build
	docker-compose up mongoshardcfg

compose-shardnode: build
	docker-compose up mongoshardnode

compose-shardmongos: build
	docker-compose up mongos

