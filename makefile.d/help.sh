#!/usr/bin/env bash

help_type=$1

function entrance {
cat << _EOF_
Usage:
    'make help' to get all usage
    'make list' list all project
    'make setup' to initialise environment
_EOF_
}


function ecs_helper {
cat << _EOF_
*******************************************************************************
*Usage:
*    Ecs service prod/release:
*        ecs-update + project + env + region
*        e.g:
*            make ecs-update-w-insights region=us-east-1 env=release
*    Ecs static website prod/release:
*        ## Step1 update static website cf stack
*        ecs-update-cf + project + env + region + static
*        ## Step2 run updated task definition one time
*        ecs-update + project + env + region + static
*        e.g:
*            make ecs-update-cf-w-m-course-static region=cn-north-1 env=release
*            make ecs-update-w-m-course-static region=cn-north-1 env=release
*    Ecs handler:
*        ## handler ecs update with consul-template
*        ecs-handler + project + region + env
*        e.g:
*            make ecs-handler-s-search-grant-solr region=cn-north-1 env=release
*    Ecs register:
*        ## register json format to consul
*        ecs-register + project + region + env
*        e.g:
*            make ecs-register-s-grant-solr region=cn-north-1 env=release
*    Ecs skeleton:
*        ## create parameter skeleton into consul
*        ecs-skeleton + project + region + env
*        e.g:
*            make ecs-skeleton-s-grant-solr region=cn-north-1 env=release
*    Ecs Ecr sync images:
*        ecs-ecr-sync + image + team + region
*        e.g:
*            make ecs-ecr-sync  image="image1:1.1 image2:2.2" team=insights region=cn
*        "If you want to list all projects , try 'make list'"
*If you want to list all projects , try 'make list'****************************
*******************************************************************************
_EOF_
}

function list_projects {
    for i in `ls apps/` ; do for j in `ls apps/$i` ; do [ ! -f $j ] && for k in `ls -d apps/$i/$j` ; do echo $k| awk -F '/' '{print $NF}' ;done  ;done;done
}

case ${help_type} in
ecs) ecs_helper
;;
entrance)entrance
;;
list)list_projects
;;
*) ecs_helper
;;
esac

