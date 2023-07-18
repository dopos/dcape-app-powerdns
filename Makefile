# powerdns init Makefile
# This file included by ../../Makefile
SHELL                 = /bin/bash
CFG                  ?= .env

# Docker image version tested for actual dcape release
PDNS_VER0            ?= v4.8.0

# powerdns docker image
PDNS_IMAGE0          ?= ghcr.io/dopos/powerdns-alpine

#- ******************************************************************************
#- Powerdns: general config

#- Powerdns API key for DNS-01 ACME challenges
PDNS_API_KEY         ?= $(DCAPE_PDNS_API_KEY)

# Next attempt: generate
PDNS_API_KEY         ?= $(shell openssl rand -hex 16; echo)

#- [ip:]port powerdns listen on (tcp & udp)
PDNS_LISTEN          ?= 54

#- Query log yes/no
PDNS_LOG_DNS_QUERIES ?= no
#- Query log works with level=5
PDNS_LOGLEVEL        ?= 4

# ------------------------------------------------------------------------------
# Makefile internal use

# Bootstrap new database
DB_INIT_SQL      ?= schema.pgsql.sql

# ------------------------------------------------------------------------------

-include $(CFG)
export

# define CONFIG_CUSTOM
# # ------------------------------------------------------------------------------
# # Sample config for .env
# #SOME_VAR=value
#
# endef

# ------------------------------------------------------------------------------
# Find and include DCAPE_ROOT/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_ROOT      ?= $(shell docker inspect -f "{{.Config.Labels.dcape_root}}" $(DCAPE_COMPOSE))

ifeq ($(DCAPE_STACK),yes)
  include Makefile.dcape
else
  include Makefile.app
endif
