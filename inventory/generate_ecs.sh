#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ECS with Consul Template v0.19.3
#
# Docker, Inc. (c) 2015-
#
# ------------------------------------------------------------------------------

# global parameter
export VAULT_ADDR='http://vault'

# Load dependencies
. ./output_lib.sh
. ./parameter_lib.sh
. ./functions_lib.sh

function helper () {
echo "ERROR: $*.. exiting..."
cat <<_EOF_

$0      -p project -r region -e env [-o]

        -p project             Required,Comma delimited list of project name, \
                                    Put primary project in front of all.[env_type]Starts with 's' or 't'.
        -e env                 Required,Available with 'ci'|'qa'|'st'|'release'|'prod2'.
        -r region              Required,Region. only supports local, cn-north-1, us-east-1
        -o                     Optional, Run in one time, default None.
        -f                     Optional, Force create template task/config files

usage example: bash $0 -p s-search-patent-solr -e release -r cn-north-1
_EOF_
        exit 1
}

## transfer parameters
while getopts "p:e:r:of?h" flag; do
    case $flag in
        p)      project=$OPTARG   	          ;;
        o)      run_mode='-once'                ;;
        r)      region=$OPTARG                  ;;
        e)      env=$OPTARG                     ;;
        f)      run_flag='force'                ;;
        ?|h)    helper                          ;;
    esac
done

info "INSTALLING CONSUL TEMPLATE"
# create template task file
consul_template_task_load

# create template config file
consul_template_config_load

# create app config file
consul_app_config_load

# listen consul template
consul_template_listen

