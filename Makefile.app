# dcape-app-powerdns Makefile
# for separate app

SHELL          = /bin/bash

# Stats site host
APP_SITE      ?= ns.dev.test

# App names (db/user name etc)
APP_NAME      ?= powerdns

#- powerdns docker image
IMAGE         ?= $(PDNS_IMAGE0)

#- powerdns docker image version
IMAGE_VER     ?= $(PDNS_VER0)

# ------------------------------------------------------------------------------
# Makefile internal use

# PgSQL used as DB
USE_DB         = yes

# User who runs bootstrap code
DB_ADMIN_USER  = $(PGUSER)

# Run SQL code via
DB_CONTAINER  ?= dcape-db-1

# ------------------------------------------------------------------------------
ifeq ($(shell test -e $(DCAPE_ROOT)/Makefile.app && echo -n yes),yes)
  include $(DCAPE_ROOT)/Makefile.app
else
  include /opt/dcape/Makefile.app
endif

define PGUP_4_8_0
ALTER TABLE domains ALTER COLUMN type TYPE text;
ALTER TABLE domains ADD COLUMN options TEXT DEFAULT NULL,
  ADD COLUMN catalog TEXT DEFAULT NULL;

CREATE INDEX catalog_idx ON domains(catalog);
endef

up-4.8.0:
	@echo "$${PGUP_4_8_0}" | docker exec -i $$PG_CONTAINER psql -U $$PGUSER $$PGDATABASE

test:
	curl -s -H 'X-API-Key: $(PDNS_API_KEY)' $(HTTP_PROTO)://$(APP_SITE)/pdns/api/v1/servers/localhost/zones | jq '.'
