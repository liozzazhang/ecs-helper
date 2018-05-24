#!/usr/bin/env bash

## build-in parameters
consul_addr=xxx
consul_token=xxx
env_list=(ci qa st dev prod2 release prod release2)
env_local=(ci qa st dev qa2)
region_list=(local cn-north-1 us-east-1)
templates_path=../templates
config_path=../configs
tpl_path=../infra
container_definition_unit='
{ {{ range ls "DEPLOY_TARGET_URI/container" }}
            "{{ .Key }}": {{ .Value }},{{ end }}
            "environment": [ {{ range ls "DEPLOY_TARGET_URI/environment" }}
                {
                    "name": "{{ .Key }}",
                    "value": "{{ .Value }}"
                },{{ end }}
                {
                    "name": "ZHIHUIYA_ZABBIX",
                    "value": "zabbix.zhihuiya.private"
                }
            ]
        }
'