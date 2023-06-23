TEMPDIR_INFOSECTOOLS = /tmp/infosec-dev-tools
VENV=.venv

install_pre_commit: check_venv
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

check_venv:
ifndef VIRTUAL_ENV
	echo "ERROR: Not in a virtual environment"
	exit 1
endif

venv_create:
	python -m venv $(VENV)
	echo "Virtual environment $(VENV) created, activate running: source $(VENV)/bin/activate"

install: check_venv
	pip install -e .

run:
	python manage.py runserver

clean:
	rm -rf __pycache__
	find . -name "*.pyc" -exec rm -f {} \;
