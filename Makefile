# dcape-app-powerdns Makefile

SHELL               = /bin/bash
CFG                ?= .env

# Database name and database user name
DB_USER            ?= pdns
# Database user password
DB_PASS            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# DNS tcp/udp port
SERVICE_PORT       ?= 54

# Stats site host
APP_SITE           ?= ns.dev.lan
# Stats login
STATS_USER         ?= admin
# Stats password
STATS_PASS         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)

# Docker image name
IMAGE              ?= dopos/powerdns
# Docker image tag
IMAGE_VER          ?= 0.1
# Docker-compose project name (container name prefix)
PROJECT_NAME       ?= pdns
# dcape container name prefix
DCAPE_PROJECT_NAME ?= dcape
# dcape network attach to
DCAPE_NET          ?= $(DCAPE_PROJECT_NAME)_default
# dcape postgresql container name
DCAPE_DB           ?= $(DCAPE_PROJECT_NAME)_db_1

# Path to schema.pgsql.sql in PowerDNS docker image
PGSQL_PATH         ?= /usr/share/doc/pdns/schema.pgsql.sql

define CONFIG_DEF
# ------------------------------------------------------------------------------
# PowerDNS settings

# DNS server port
SERVICE_PORT=$(SERVICE_PORT)

# Database name and database user name
DB_USER=$(DB_USER)
# Database user password
DB_PASS=$(DB_PASS)

# PowerDNS statistics

# Stats site host
APP_SITE=$(APP_SITE)

# Stats login
STATS_USER=$(STATS_USER)
# Stats password
STATS_PASS=$(STATS_PASS)

# Docker details

# Docker image name
IMAGE=$(IMAGE)
# Docker image tag
IMAGE_VER=$(IMAGE_VER)
# Docker-compose project name (container name prefix)
PROJECT_NAME=$(PROJECT_NAME)
# dcape network attach to
DCAPE_NET=$(DCAPE_NET)
# dcape postgresql container name
DCAPE_DB=$(DCAPE_DB)

endef
export CONFIG_DEF

-include $(CFG)
export

.PHONY: all $(CFG) setup start stop up reup down docker-wait db-create db-drop psql dc help

all: help

# ------------------------------------------------------------------------------
# webhook commands

start: db-create up

start-hook: db-create reup

stop: down

update: reup

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
	@until [[ `docker inspect -f "{{.State.Health.Status}}" $$DCAPE_DB` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

# create user, db and load sql
db-create: docker-wait
	@echo "*** $@ ***" ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE USER \"$$DB_USER\" WITH PASSWORD '$$DB_PASS';" || true ; \
	docker exec -i $$DCAPE_DB psql -U postgres -c "CREATE DATABASE \"$$DB_USER\" OWNER \"$$DB_USER\";" || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] ; then \
	  docker run -t --rm $$IMAGE:$$IMAGE_VER cat $(PGSQL_PATH) | docker exec -i $$DCAPE_DB psql -U $$DB_USER -f - ; \
	fi

## drop database and user
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -it $$DCAPE_DB psql -U postgres -c "DROP DATABASE \"$$DB_USER\";" || true
	@docker exec -it $$DCAPE_DB psql -U postgres -c "DROP USER \"$$DB_USER\";" || true

psql: docker-wait
	@docker exec -it $$DCAPE_DB psql -U $$DB_USER

# ------------------------------------------------------------------------------

# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@AUTH=$$(htpasswd -nb $$STATS_USER $$STATS_PASS) ; \
	docker run --rm  \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v $$PWD:$$PWD \
	  -w $$PWD \
	  --env=AUTH=$$AUTH \
	  docker/compose:1.14.0 \
	  -p $$PROJECT_NAME \
	  $(CMD)

# ------------------------------------------------------------------------------

$(CFG):
	@[ -f $@ ] || echo "$$CONFIG_DEF" > $@

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
