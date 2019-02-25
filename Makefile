ifndef APP_ENV
	include .env
	include .env.local
endif

CONSOLE=bin/console
PHPCSFIXER=vendor/bin/php-cs-fixer
PHPUNIT=bin/phpunit
TWIGCS=vendor/bin/twigcs
YARN=yarn

.DEFAULT_GOAL := help
.PHONY: help deploy start start-dev clear clean cc db db-create db-migrations watch asset asset-prod deps test tf tu tj
.PHONY: csphp csjs cscss cstwig perm on-maintenance off-maintenance autoload-optimize

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | grep -v '###>' | grep -v '###<' | sed -e 's/##//'

##
## TravisTest
##


##
## Project setup
##---------------------------------------------------------------------------

deploy:         ## Install and start the project
deploy: on-maintenance db asset-prod deps cc autoload-optimize perm off-maintenance

start:          ## Install and start the project in dev
start: db asset deps cc perm

clear:          ## Remove all the cache, the logs, the sessions
clear: perm
	rm -rf var/cache/*
	rm -rf var/sessions/*
	rm -rf var/logs/*

clean:          ## Clear and remove dependencies
clean: clear

cc:             ## Clear the cache in dev env
cc:
	$(CONSOLE) cache:clear

test-cc: test-env cc



##
## Database
##---------------------------------------------------------------------------

db:             ## Create database
db: vendor db-create db-migrations perm


db-create:
	$(CONSOLE) doctrine:database:create --if-not-exists


db-migrations:
	$(CONSOLE) doctrine:migrations:migrate -n

db-test:
db-test: vendor db-test-create db-test-migrations perm

db-test-create:
	NODE_ENV=test APP_ENV=test $(CONSOLE) doctrine:database:create --if-not-exists

db-test-migrations:
	NODE_ENV=test APP_ENV=test $(CONSOLE) doctrine:migrations:migrate -n




##
## Assets
##---------------------------------------------------------------------------

watch:          ## Watch the assets and build their development version on change
watch: node_modules
	$(YARN) watch

asset:          ## Build the development version of the assets
asset: assets node_modules
	$(YARN) dev

asset-prod:     ## Build the production version of the assets
asset-prod: assets node_modules
	$(YARN) build --no-save




##
## Dependencies
##---------------------------------------------------------------------------

deps:           ## Install the project PHP dependencies
deps: vendor public/build/manifest.json




##
## Tests
##---------------------------------------------------------------------------

test:           ## Run the PHP and the Javascript tests
test: tu tf csphp tj csjs cscss

tf:             ## Run phpunit functional tests
tf: deps cc db-test
	$(PHPUNIT) --group functional

tu:             ## Run phpunit unit tests
tu: vendor
	$(PHPUNIT) --exclude-group functional

tj:             ## Run the Javascript tests
tj: node_modules
	$(YARN) test

csphp:          ## Lint PHP code
csphp: vendor
	$(PHPCSFIXER) fix --diff --dry-run --no-interaction -v

csjs:           ## Lint Javascript code
csjs: node_modules
	$(YARN) lint

cscss:          ## Lint CSSs
cscss: node_modules
	$(YARN) css

cstwig:          ## Lint CSSs
cstwig: vendor
	$(TWIGCS) ./templates/




##
# Internal rules

perm:
	setfacl -dR -m u:`ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`:rwX -m u:$(whoami):rwX var 2>/dev/null || true
	setfacl -R -m u:`ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1`:rwX -m u:$(whoami):rwX var 2>/dev/null || true

autoload-optimize:
	if [ "${APP_ENV}" = "prod" ]; then composer dump-autoload -o --no-dev; fi

on-maintenance:
	@echo Performing maintenance mode
	mkdir -p var
	touch var/maintenance.lock
	sleep 5

off-maintenance:
	@echo Performing prod mode
	rm -rf var/maintenance.lock




# Rules from files

vendor: composer.lock
	if [ "${APP_ENV}" = "prod" ]; then composer install --no-dev; else composer install; fi

composer.lock: composer.json
	@echo composer.lock is not up to date.

node_modules: package.json
	$(YARN) install

package-lock.json: package.json
	@echo package-lock.json is not up to date.

public/build/manifest.json: assets node_modules
	$(YARN) build

.env.local:
	@echo Please edit .env.local file
	touch .env.local
