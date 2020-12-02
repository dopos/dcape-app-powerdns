# dcape-app-powerdns Makefile

SHELL               = /bin/sh
CFG                ?= .env

# DNS tcp/udp port
SERVICE_PORT       ?= 54

# Database name
PGDATABASE         ?= pdns
# Database user name
PGUSER             ?= pdns
# Database user password
PGPASSWORD         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# Stats site host
APP_SITE           ?= ns.dev.lan

# Powerdns API key for DNS-01 ACME challenges
API_KEY            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# External DNS server hostname
NS_HOST            ?= $(APP_SITE)

# Docker image name
IMAGE              ?= psitrax/powerdns
# Docker image tag
IMAGE_VER          ?= v4.3
# Docker-compose project name (container name prefix)
COMPOSE_PROJECT_NAME       ?= $(shell basename $$PWD)
# dcape container name prefix
DCAPE_TAG          ?= dcape
# dcape network attach to
DCAPE_NET          ?= $(DCAPE_TAG)_default
# dcape postgresql container name
PG_CONTAINER       ?= $(DCAPE_TAG)_db_1

define CONFIG_DEF
# ------------------------------------------------------------------------------
# PowerDNS settings

# DNS server port
SERVICE_PORT=$(SERVICE_PORT)

# External DNS server hostname
NS_HOST=$(NS_HOST)

# Stats site host
APP_SITE=$(APP_SITE)

# Powerdns API key for DNS-01 ACME challenges
API_KEY=$(API_KEY)

# Database name
PGDATABASE=$(PGDATABASE)
# Database user name
PGUSER=$(PGUSER)
# Database user password
PGPASSWORD=$(PGPASSWORD)

# Docker details

# Docker image name
IMAGE=$(IMAGE)
# Docker image tag
IMAGE_VER=$(IMAGE_VER)

# Used by docker-compose
# Docker-compose project name (container name prefix)
COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME)

# dcape container name prefix
DCAPE_TAG=$(DCAPE_TAG)

# dcape network attach to
DCAPE_NET=$(DCAPE_NET)

# dcape postgresql container name
PG_CONTAINER=$(PG_CONTAINER)

endef
export CONFIG_DEF

-include $(CFG)
export

.PHONY: all $(CFG) update start stop up reup down docker-wait db-create db-drop psql dc help

all: help

# ------------------------------------------------------------------------------
# dcape v1 webhook commands

start: db-create up

start-hook: db-create reup

stop: down

update: reup

$(CFG): $(CFG).sample

# ------------------------------------------------------------------------------
# docker commands

## старт контейнеров
up:
up: CMD=up -d
up: dc

## рестарт контейнеров
reup:
reup: CMD=up --force-recreate -d
reup: dc

## остановка и удаление всех контейнеров
down:
down: CMD=rm -f -s
down: dc

# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..."
	@until [ `docker inspect -f "{{.State.Health.Status}}" $$PG_CONTAINER` = "healthy" ] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

# create user, db and load sql
db-create: docker-wait
	@echo "*** $@ ***" ; \
	sql="CREATE USER \"$$PGUSER\" WITH PASSWORD '$$PGPASSWORD'" ; \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "$$sql" 2>&1 > .psql.log | grep -v "already exists" > /dev/null || true ; \
	cat .psql.log ; \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE DATABASE \"$$PGDATABASE\" OWNER \"$$PGUSER\";" 2>&1 > .psql.log | grep  "already exists" > /dev/null || db_exists=1 ; \
	cat .psql.log ; \
	if [ "$$db_exists" = "1" ] ; then \
	  echo "*** db data load" ; \
	  cat schema.pgsql.sql | docker exec -i $$PG_CONTAINER psql -U $$PGUSER -d $$PGDATABASE -f - ; \
	fi

## drop database and user
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -it $$PG_CONTAINER psql -U postgres -c "DROP DATABASE \"$$PGDATABASE\";" || true
	@docker exec -it $$PG_CONTAINER psql -U postgres -c "DROP USER \"$$PGUSER\";" || true

psql: docker-wait
	@docker exec -it $$PG_CONTAINER psql -U $$PGUSER $$PGDATABASE

# ------------------------------------------------------------------------------

# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@docker run --rm  \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v $$PWD:$$PWD \
	  -w $$PWD \
	  docker/compose \
	  $(CMD)

# ------------------------------------------------------------------------------

$(CFG).sample:
	@echo "$$CONFIG_DEF" > $@
	@echo "$@ Created. Edit and rename to $(CFG)"

## generate sample config
config: $(CFG).sample

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
