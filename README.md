# ECS-HELPER
[![Build Status](http://img.shields.io/travis/hashicorp/consul-template.svg?style=flat-square)](http://git.patsnap.com/devops/containers)

This project handles consul based ecs auto deployment. 

## Warning
This project `not support` MacOS.

## Preparation
1. external `consul` server and `vault` server(not provided here).Then modify following files about consul/vault address and token.

```text
1. this is core function, need define the vault address.
inventory/generate_ecs.sh 
##export VAULT_ADDR='http://vault'

2. this is project parameters sh, all params you need locate in here.
inventory/parameter_lib.sh 
##consul_addr=xxx
##consul_token=xxx

3. this is used to register your exist project parameters to consul
inventory/kv_registor.py 
## consul = 'CONSUL ADDRESS'
## consul_token = 'xxx' 

4. this shell is used to create parameter structure in consul, when you first use this helper, please run it!
inventory/skeleton.sh
##consul_master=xxx
##consul_token=xxx

5. this tpl is consul template config tpl. 
infra/config.tpl
########################
consul {
  address = "consul"
  token = "xxx"
}
vault {
  address = "http://vault"
  token = "xxx"
  renew_token = false
}
########################

```
  
2. Setup `consul` and `consul-template` package
```bash
make setup
```
3. external `ops` and `jarvis` python library.
```bash
sudo pip install common-ops
sudo pip install jarvis-helper
```
##Quick Run
1. start a new project, you can create a consul skeleton .
```bash
# ecs-skeleton + project + region + env
make ecs-skeleton-s-test-src region=cn-north-1 env=release
```
If you already have a project, register your project parameter to consul
```bash
# make ecs-register + project + region + env
make ecs-register-s-search-ac-solr region=cn-north-1 env=release
```
2. Run 
```text
# ecs-handler + project + region + env

make ecs-handler-s-test-src region=cn-north-1 env=release

This job handle following things:
    - makefile parameter validation check
    - create task and config templates if not exists
    - read parameter from consul and write to apps/ dir
    - task definition container environment change set review
    - update task definition new version
    - update ecs service
```
