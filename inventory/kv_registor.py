#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Time    : 26/10/2017 23:51
# @Author  : Liozza
# @Site    : 
# @File    : kv_registor.py
# @Software: PyCharm

import json
import subprocess
import sys
import re
from ops.args import ArgsHandle


class KVRegister(object):
    def __init__(self, task_path):
        self.__file_path = task_path
        self.__register_flag = False
        self.__color_head = '\033[1;34;34m'
        self.__color_tail = '\033[0m'
        self.__project_color_head = '\033[1;34;36m'
        self.__project_color_tail = '\033[0m'

    def convert_json2kv(self, file_path):
        with open(file_path, 'r') as f:
            json_content = json.load(f)
            json_content_task_definition_dict = {
                'environment': [],
                'container': [],
                'task': {}
            }
            for key in json_content.keys():
                if key == 'containerDefinitions':
                    for index in range(len(json_content['containerDefinitions'])):
                        container_dict = {}
                        for sub_key, sub_value in json_content['containerDefinitions'][index].items():
                            if sub_key == 'environment':
                                json_content_task_definition_dict['environment'].append(sub_value)
                            else:
                                container_dict['%s' % sub_key] = sub_value
                        json_content_task_definition_dict['container'].append(container_dict)
                else:
                    json_content_task_definition_dict['task']['%s' % key] = json_content[key]
            return json_content_task_definition_dict

    def register_value2kv(self, task_env_dict, team, tag, consul_master, consul_master_token,
                          file_format="json", env="release", region='cn-north-1'):
        env_type = project_name[0]
        if env_type == 's':
            env_type = 'service'
        elif env_type == 'w':
            env_type = 'website'
        else:
            print "Invalid env_type, should start with 'w' or 's'"
            sys.exit()

        # if project name is same as container name
        for index in range(len(task_env_dict['container'])):
            project = task_env_dict['container'][index]['name']
            if project == project_name:
                self.__register_flag = True
                break
        if not self.__register_flag:
            sys.exit("Container Name Must be the same as Project Name!")

        for key, value in task_env_dict.items():
            # separate container| environment|task parameters
            if isinstance(value, list):
                for sub_index in range(len(value)):
                    project = task_env_dict['container'][sub_index]['name']
                    print '''%s======================================\n\t%s\n======================================%s'''% (self.__project_color_head, project, self.__project_color_tail)
                    if key == 'environment':
                        print "%senvironments parameters:%s " % (self.__color_head, self.__color_tail)
                        for index in range(len(value[sub_index])):
                            if value[sub_index][index]['name'] != 'ZHIHUIYA_ZABBIX':
                                env_key = value[sub_index][index]['name']
                                env_value = value[sub_index][index]['value']
                                print env_key + '=' + env_value
                                # transfer u'' to ""
                                env_value = str(env_value).replace('u\'', '\\\"')
                                env_value = str(env_value).replace('\'', '\\\"')
                                cmd = "consul kv put -token=%s --http-addr=%s " \
                                      "\"Microservices/%s/%s/%s/%s/environment/%s\" \"%s\"" % \
                                      (consul_master_token, consul_master, team, project, env, region, env_key, env_value)
                                subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)
                    if key == 'container':
                        print "%scontainer parameters:%s " % (self.__color_head, self.__color_tail)
                        for env_key, env_value in value[sub_index].items():
                            print '''%s = %s''' % (env_key, env_value)
                            # # transfer u'' to ""
                            if isinstance(env_value, list):
                                env_value = str(env_value).replace('u\'', '\\\"')
                                env_value = str(env_value).replace('\'', '\\\"')
                            elif isinstance(env_value, unicode):
                                env_value = '\\\"' + env_value + '\\\"'
                            elif isinstance(env_value, bool):
                                env_value = str(env_value).lower()
                            cmd = "consul kv put -token=%s --http-addr=%s " \
                                  "\"Microservices/%s/%s/%s/%s/container/%s\" \"%s\"" % \
                                  (consul_master_token, consul_master, team, project, env, region, env_key, env_value)
                            subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)

                        print "%stask parameters:%s " % (self.__color_head, self.__color_tail)
                        for sub_key, sub_value in task_env_dict['task'].items():
                            print '''%s = %s''' % (sub_key, sub_value)
                            # # transfer u'' to ""
                            if isinstance(sub_value, list):
                                sub_value = str(sub_value).replace('u\'', '\\\"')
                                sub_value = str(sub_value).replace('\'', '\\\"')
                            elif isinstance(sub_value, unicode):
                                sub_value = '\\\"' + sub_value + '\\\"'
                            elif isinstance(sub_value, bool):
                                sub_value = str(sub_value).lower()
                            cmd = "consul kv put -token=%s --http-addr=%s " \
                                  "\"Microservices/%s/%s/%s/%s/task/%s\" \"%s\"" % \
                                  (consul_master_token, consul_master, team, project, env, region, sub_key,
                                   sub_value)
                            subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)

                        # deploy environments
                        deploy_env_dict = {
                            'deploy_target_uri': '%s/%s/%s/%s' % (project, env, region, env_type),
                            'target':   '%s-%s' % (project, project_env),
                            'project':  project,
                            'region':   region,
                            'env':  env,
                            'tag':  tag,
                            'format': file_format,
                            'team': team
                        }
                        print "%sdeploy parameters:%s " % (self.__color_head, self.__color_tail)
                        for deploy_key, deploy_value in deploy_env_dict.items():
                            print '''%s = %s''' % (deploy_key, deploy_value)
                            cmd = "consul kv put -token=%s --http-addr=%s \"Microservices/%s/%s/%s/%s/deploy/%s\" \"%s\"" % \
                                  (consul_master_token, consul_master, team, project, env, region, deploy_key, deploy_value)
                            subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)


if __name__ == '__main__':
    kv_register_args = ArgsHandle().get_args()
    consul = 'CONSUL ADDRESS'
    consul_token = 'xxx'
    ecs_file_format = ''
    project_name = kv_register_args['project']
    project_env = kv_register_args['env']
    project_region = kv_register_args['region']
    project_tag = kv_register_args['tag']
    project_team = ''.join(re.split('-', project_name)[1:2])

    if 'details' in kv_register_args.keys():
        if 'format' in kv_register_args['details'].keys():
            ecs_file_format = kv_register_args['details']['format']
        else:
            ecs_file_format = 'json'

    project_file = '../apps/%s/%s/%s/%s/task.json' % (project_team, project_name, project_env, project_region)
    register = KVRegister(task_path=project_file)
    project_env_dict = register.convert_json2kv(file_path=project_file)
    # print project_env_dict
    register.register_value2kv(env=project_env, region=project_region, team=project_team,
                               tag=project_tag, file_format=ecs_file_format, task_env_dict=project_env_dict,
                               consul_master=consul, consul_master_token=consul_token)
