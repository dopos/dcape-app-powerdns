# powerdns init Makefile
# This file included by ../../Makefile
SHELL             = /bin/bash
CFG              ?= .env

# Docker image version tested for actual dcape release
PDNS_VER0        ?= v4.8.0

#- ******************************************************************************
#- Powerdns: general config

#- [ip:]port powerdns listen on
PDNS_LISTEN      ?= 54
#- Stats site host
PDNS_HOST        ?= ns.$(DCAPE_DOMAIN)
#- Wildcard zone nameserver
#- NS value for $(DCAPE_DOMAIN) CNAME record
#- Used for zone SOA record & for internal access from traefik
ACME_NS          ?= ns.$(DCAPE_DOMAIN)
#- Setup ACME zone for this domain
#- CNAME value for $(DCAPE_DOMAIN) record
ACME_DOMAIN      ?= acme-$(DCAPE_DOMAIN)
#- Admin email for wildcard zone SOA recors
ACME_ADMIN_EMAIL ?= $(TRAEFIK_ACME_EMAIL)

#- ------------------------------------------------------------------------------
#- Powerdns: internal config

#- Database name and database user name
PDNS_DB_TAG      ?= pdns
#- Database user password
PDNS_DB_PASS     ?= $(shell openssl rand -hex 16; echo)
#- Powerdns API key for DNS-01 ACME challenges
PDNS_API_KEY     ?= $(DCAPE_PDNS_API_KEY)

#- powerdns docker image
PDNS_IMAGE       ?= ghcr.io/dopos/powerdns-alpine
#- powerdns docker image version
PDNS_VER         ?= $(PDNS_VER0)

#- dcape root directory
DCAPE_ROOT       ?= $(DCAPE_ROOT)

APP_ROOT         ?= $(PWD)
NAME             ?= PDNS
DB_INIT_SQL      ?= schema.pgsql.sql
DB_ADMIN_USER     = $(PDNS_DB_TAG)

#for powerdns-load-zone
DB_CONTAINER     ?= dcape-db-1
# ------------------------------------------------------------------------------

-include $(CFG)
export

ifdef DCAPE_STACK
include $(DCAPE_ROOT)/Makefile.dcape
else
include $(DCAPE_ROOT)/Makefile.app
endif

init:
	@if [[ "$$PDNS_VER0" != "$$PDNS_VER" ]] ; then \
	  echo "Warning: PDNS_VER in dcape ($$PDNS_VER0) differs from yours ($$PDNS_VER)" ; \
	fi
	@echo "  Stats URL: $(DCAPE_SCHEME)://$(PDNS_HOST)"
	@echo "  Listen: $(PDNS_LISTEN)"

# create user, db and load sql
.setup-before-up: db-create db-load-acme

db-load-acme:
	@echo "*** $@ ***" ; \
	[[ "$$DNS" != "wild" ]] || cat $(APP_ROOT)/setup.acme.sql | $(MAKE) -s compose CMD="exec -T db psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG -vACME_DOMAIN=$$ACME_DOMAIN -vACME_NS=$$ACME_NS -vNS_ADMIN=$$ACME_ADMIN_EMAIL" || true

# load powerdns zone from zone.sql
powerdns-load-zone: zone.sql docker-wait
	cat zone.sql | docker exec -i $$DB_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG
