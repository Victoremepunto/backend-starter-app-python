TEMPDIR_INFOSECTOOLS = /tmp/infosec-dev-tools
VENV=.venv
COVERAGE_REPORT_FORMAT = 'html'
IMAGE=quay.io/${USER}/backend-starter-app
IMAGE_TAG=latest
DOCKERFILE=Dockerfile
CONTAINER_WEBPORT=8000
HOST_WEBPORT=${CONTAINER_WEBPORT}
CONTEXT=.
CONTAINER_ENGINE=podman
BONFIRE_CONFIG=".bonfirecfg.yaml"
CLOWDAPP_TEMPLATE=clowdapp.yaml
CLOWDAPP_NAME=backend-starter-app-python

run: venv_check
	python manage.py runserver

install_pre_commit: venv_check
	# Remove any outdated tools
	rm -rf $(TEMPDIR_INFOSECTOOLS)
	# Clone up-to-date tools
	git clone https://gitlab.corp.redhat.com/infosec-public/developer-workbench/tools.git /tmp/infosec-dev-tools

	# Cleanup installed old tools
	$(TEMPDIR_INFOSECTOOLS)/scripts/uninstall-legacy-tools

	# install pre-commit and configure it on our repo
	make -C $(TEMPDIR_INFOSECTOOLS)/rh-pre-commit install
	python -m rh_pre_commit.multi configure --configure-git-template --force
	python -m rh_pre_commit.multi install --force --path ./

	rm -rf $(TEMPDIR_INFOSECTOOLS)

venv_check:
ifndef VIRTUAL_ENV
	$(error Not in a virtual environment)
endif

venv_create:
ifndef VIRTUAL_ENV
	python -m venv $(VENV)
	@echo "Virtual environment $(VENV) created, activate running: source $(VENV)/bin/activate"
else
	$(warning VIRTUAL_ENV variable present, already within a virtual environment?)
endif

install: venv_check
	pip install -e .

install_dev: venv_check
	pip install -e .[dev]

clean:
	rm -rf __pycache__
	find . -name "*.pyc" -exec rm -f {} \;

test: venv_check install_dev
	python manage.py test

coverage: venv_check install_dev
	coverage run --source="." manage.py test
	coverage $(COVERAGE_REPORT_FORMAT)

coverage-ci: COVERAGE_REPORT_FORMAT=xml
coverage-ci: coverage

build-container:
	${CONTAINER_ENGINE} build -t ${IMAGE} -f ${DOCKERFILE} ${CONTEXT}

run-container:
	${CONTAINER_ENGINE} run -it --rm -p ${HOST_WEBPORT}:${CONTAINER_WEBPORT} ${IMAGE} runserver 0.0.0.0:8000

build-container-docker: CONTAINER_ENGINE=docker
build-container-docker: build-container

run-container-docker: CONTAINER_ENGINE=docker
run-container-docker: run-container

push-image:
	${CONTAINER_ENGINE} push ${IMAGE}

bonfire_process: $(BONFIRE_CONFIG)
	@bonfire process -c $(BONFIRE_CONFIG) $(CLOWDAPP_NAME) \
		-p service/IMAGE=$(IMAGE) -p service/IMAGE_TAG=$(IMAGE_TAG) -n foo

bonfire_write_config: $(BONFIRE_CONFIG)
$(BONFIRE_CONFIG):
	@sed "s|##BONFIRE_REPODIR##|${PWD}|;\
	s|##BONFIRE_APPNAME##|$(CLOWDAPP_NAME)|;\
	s|##BONFIRE_CLOWDAPP_TEMPLATE##|$(CLOWDAPP_TEMPLATE)|" < templates/bonfire_config > $(BONFIRE_CONFIG)

bonfire_deploy: $(BONFIRE_CONFIG)
	bonfire deploy -c $(BONFIRE_CONFIG) \
		-p service/IMAGE=$(IMAGE) -p service/IMAGE_TAG=$(IMAGE_TAG)  $(CLOWDAPP_NAME)
