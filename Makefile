# Check that given variables are set and all have non-empty values, die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
SETUP_OS_TYPE?=$(shell uname)
SETUP_CONSUL_TEMPLATE_VERSION?=0.19.4
SETUP_CONSUL_VERSION?=1.0.7

#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

## default makefile target
entrance::
	@sh makefile.d/help.sh entrance

help::
	@sh makefile.d/help.sh

list::
	@sh makefile.d/help.sh list

ecs::
	@sh makefile.d/help.sh ecs
check-region::
	@:$(call check_defined, region, the region is required! the example: make <target> region=cn-north-1)

check-env::
	@:$(call check_defined, env, the env is required! the example: make <target> env=release)

setup::
	@echo "--- Setup Consul Template ---"
	@consul-template --help > /dev/null 2>&1 && \
	(echo "--- Consul Template Already Exists ---" && \
	consul-template --version) || \
	(curl -o /usr/local/bin/consul-template http://repo.patsnap.com/downloads/software/Consul-template/consul-template_$(SETUP_CONSUL_TEMPLATE_VERSION)_$(SETUP_OS_TYPE) && \
	chmod +x /usr/local/bin/consul-template && \
	echo "--- Installed Consul Template ---")
	@echo "--- Setup Consul ---"
	@consul --help > /dev/null 2>&1 && \
	(echo "--- Consul Already Exists ---" && \
	consul --version ) || \
	(curl -o /usr/local/bin/consul http://repo.patsnap.com/downloads/software/consul/consul_$(SETUP_CONSUL_VERSION)_$(SETUP_OS_TYPE) && \
	chmod +x /usr/local/bin/consul && \
	echo "--- Installed Consul ---")

# Ignore include errors
-include makefile.d/ecs.mk