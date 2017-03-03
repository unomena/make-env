NOW = $(shell date +"%Y%m%d-%H%M%S")
DB_DIR = /home/ubuntu/databases
BACKUP_DIR = /home/ubuntu/databases/old

all: help

help:
	@echo
	@echo "Unomena Code deployment and server updates"
	@echo "------------------------------------------"
	@echo

	@echo "Resetting the BD to the latest from production:"
	@echo "* make replace-db app=tellmeplus"
	@echo
	@echo "Deploying the latest code from a branch:"
	@echo "* make deploy-code app=barefoot branch=qa"
	@echo "* make deploy-code app=diamanti branch=release/1.23.4"
	@echo
	@echo "Restoring the latest media:"
	@echo "* make replace-media app=netronome"
	@echo
	@echo "All of the above:"
	@echo "* make update app=influans"
	@echo
	@echo "where app in [barefoot, diamanti, gcro, influans, netronome, open-nfp]"
	@echo
	@echo "Instance Type: "$(INSTANCE_TYPE)

replace-db:
	@echo "Shutting down services..."
ifeq ($(INSTANCE_TYPE),dev)
	sudo supervisorctl stop $(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl stop $(app).$(INSTANCE_TYPE).unomena.net.gunicorn
else
	sudo supervisorctl stop prod.$(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl stop prod.$(app).$(INSTANCE_TYPE).unomena.net.gunicorn
	sudo supervisorctl stop stage.$(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl stop stage.$(app).$(INSTANCE_TYPE).unomena.net.gunicorn
endif

	@echo "Backing up old database..."
	mkdir -p $(BACKUP_DIR)
	sudo -u postgres pg_dump -Ft $(app)_$(INSTANCE_TYPE) > $(BACKUP_DIR)/$(app)_$(INSTANCE_TYPE).db.$(NOW).tar
	gzip $(BACKUP_DIR)/$(app)_$(INSTANCE_TYPE).db.$(NOW).tar
	s3cmd sync $(BACKUP_DIR)/ s3://backup.unomena.net/archive/$(INSTANCE_TYPE)/
	rm -Rf $(BACKUP_DIR)

	@echo "Restoring the latest database from production..."
	s3cmd get --force s3://backup.unomena.net/db/$(app).db.tar.gz $(DB_DIR)/
	gunzip $(DB_DIR)/$(app).db.tar.gz
	sudo -u postgres dropdb $(app)_$(INSTANCE_TYPE)
	sudo -u postgres createdb -O $(app) $(app)_$(INSTANCE_TYPE)
	sudo -u postgres pg_restore -d $(app)_$(INSTANCE_TYPE) $(DB_DIR)/$(app).db.tar
	gzip $(DB_DIR)/$(app).db.tar

	@echo "Starting up services..."
ifeq ($(INSTANCE_TYPE),dev)
	sudo supervisorctl start $(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl start $(app).$(INSTANCE_TYPE).unomena.net.gunicorn
else
	sudo supervisorctl start prod.$(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl start prod.$(app).$(INSTANCE_TYPE).unomena.net.gunicorn
	sudo supervisorctl start stage.$(app).$(INSTANCE_TYPE).unomena.net.celeryd
	sudo supervisorctl start stage.$(app).$(INSTANCE_TYPE).unomena.net.gunicorn
endif

deploy-code:
ifeq ($(INSTANCE_TYPE),dev)
	@echo "Updating the dev instance..."
	cd /var/www/$(app)/ && git checkout master; git branch -D develop; git fetch; git checkout develop && ./build_dev.sh
else
ifeq ($(INSTANCE_TYPE),qa)
	@echo "Updating the qa prod instance..."
	cd /var/www/$(app)_prod/ && git checkout master; git branch -D qa; git fetch; git checkout qa && ./build_qa_prod.sh

	@echo "Updating the staging instance..."
	cd /var/www/$(app)_stage/ && git checkout master; git branch -D qa; git fetch; git checkout qa && ./build_qa_stage.sh
else
	@echo "Updating the prod instance..."
	cd /var/www/$(app)_prod/ && git pull origin $(branch) && ./build_$(INSTANCE_TYPE)_prod.sh

	@echo "Updating the staging instance..."
	cd /var/www/$(app)_stage/ && git pull origin $(branch) && ./build_$(INSTANCE_TYPE)_stage.sh
endif
endif

replace-media:
ifeq ($(INSTANCE_TYPE),dev)
	@echo "Deleting the media folder..."
	sudo rm -Rf /var/www/$(app)/media/*
	@echo "Getting the latest media from $(app).stage.unomena.net"
	rsync -ru stage.unomena.net:/var/share/$(app)/media/* /var/www/$(app)/media/.
	sudo chown -R www-data:unoweb /var/www/$(app)/media/
	sudo chmod -R 775 /var/www/$(app)/media/
	sudo chmod -R +s /var/www/$(app)/media/
else
	@echo "Deleting the media folder..."
	sudo rm -Rf /var/www/$(app)_stage/media/*
	@echo "Getting the latest media from $(app).stage.unomena.net"
	rsync -ru stage.unomena.net:/var/share/$(app)/media/* /var/www/$(app)_stage/media/.
	sudo chown -R www-data:unoweb /var/www/$(app)_stage/media/
	sudo chmod -R 775 /var/www/$(app)_stage/media/
	sudo chmod -R +s /var/www/$(app)_stage/media/
endif

update:
	$(MAKE) replace-db app=$(app)
	$(MAKE) replace-media app=$(app)
	$(MAKE) deploy-code app=$(app) branch=$(branch)
