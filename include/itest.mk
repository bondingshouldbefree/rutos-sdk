#
# Copyright (C) 2024 Teltonika-Networks
#

# colors
_R:=\\033[31m
_N:=\\033[m

itest:
ifeq ($(wildcard bin/targets/x86/**/tltFws/X86*_LIVE.iso),)
	$(error $(shell printf "$(_R)Integration tests can only be run with x86_64 FW. Select x86_64 and make the FW first$(_N)"))
endif # TARGET_X86_64
ifeq ($(TEST),)
	$(error $(shell printf "$(_R)No file to test.$(_N) Specify TEST=<test file>. To run tests interactively without restarting the emulator, specify TEST=shell"))
endif # TEST
	@IMG_NAME="$(GITLAB_REGISTRY_HOST)/teltonika/rutx_open/tbot" \
		IMG_TAG="$$(grep -E '^\s*\.image_tbot:.*:[\[ $$A-Za-z0-9.]+$$' .gitlab/ci/templates/images.yml | rev | cut -d':' -f1 | rev | tr -d '\n')" \
		./scripts/docker-bootstrap /run_tests.sh $(if $(findstring $(DEBUG),1),--debug) $(if $(findstring $(TEST),shell),,$(TEST))

vuci-test:
ifeq ($(wildcard bin/targets/x86/**/tltFws/X86*_LIVE.iso),)
	$(error $(shell printf "$(_R)Integration tests can only be run with x86_64 FW. Select x86_64 and make the FW first$(_N)"))
endif # TARGET_X86_64
	@IMG_NAME="$(GITLAB_REGISTRY_HOST)/teltonika/rutx_open/tbot" \
		IMG_TAG="$$(grep -E '^\s*\.image_tbot:.*:[\[ $$A-Za-z0-9.]+$$' .gitlab/ci/templates/images.yml | rev | cut -d':' -f1 | rev | tr -d '\n')" \
		./scripts/docker-bootstrap ./feeds/vuci/tests/run_integration.py --address 192.168.1.1 --password admin01 --apps_file ./feeds/vuci/tests/test_base_apps.json
