#!/usr/bin/env bash

function git_sync () {
    git fetch --all >/dev/null 2>&1
    git reset --hard origin/master >/dev/null 2>&1
    git pull origin master > /dev/null 2>&1
}

# git pull updates
function git_pull () {
    git fetch --all >/dev/null 2>&1
    git pull origin master >/dev/null 2>&1
}


function git_commit () {
    git add --all ../* >/dev/null 2>&1
    git commit -m "update" >/dev/null 2>&1
    git push origin HEAD:master >/dev/null 2>&1
}

function consul_template_task_load () {
    info "CHECK PROJECT PARAMETERS:"
    try "checking region"
    [[ ! ${region_list[@]} =~ ${region} ]] && helper "Invalid region input" || ok

    try "checking env"
    [[ ! ${env_list[@]} =~ ${env} ]] && helper "Invalid env type! Your input is: ${target}" || ok

    info "CHECK PROJECT:"
    for prounit in $(echo ${project}|sed "s/,/ /g")
    do
        try "checking project -- ${prounit}"
        if [[ "Z"${prounit} == "Z" ]] ;then
            helper "project_name is required!"
        else
            ok
            target_unit=${prounit}-${env} #  s-search-patent-solr-release
            target_unit_tmp=${target_unit#*-}        ## search-patent-solr
            team_unit=${target_unit_tmp%%-*}         ## search
            env_type_unit=${target_unit%%-*}          ## s

            case ${env_type_unit} in
            s) env_type_unit='service' ;;
            w) env_type_unit='website' ;;
            *) die "project name only starts with 's' and 'w'! Your input project name is: ${target_unit}"
               ;;
            esac

            deploy_target_uri_unit=Microservices/${team_unit}/${prounit}/${env}/${region}
            if [[ 'Z'${container_definition} == 'Z' ]];then
                container_definition=$(echo ${container_definition_unit}|sed "s|DEPLOY_TARGET_URI|${deploy_target_uri_unit}|g")
                target=${prounit}-${env} #  s-search-patent-solr-release
                target_tmp=${target#*-}        ## search-patent-solr
                team=${target_tmp%%-*}         ## search
                env_type=${target%%-*}          ## s
                short_env=${env_type}
                deploy_target_uri=Microservices/${team}/${prounit}/${env}/${region}
            else
                container_definition="$(echo ${container_definition}),\n\t$(echo ${container_definition_unit}|sed "s|DEPLOY_TARGET_URI|${deploy_target_uri_unit}|g")"
            fi
        fi
    done

    # setup path
    app_path=../apps/${team}/${project}
    ls -d ${app_path} > /dev/null 2>&1 || mkdir -p ${app_path}
    ls -d ${templates_path}/config/${region}/ > /dev/null 2>&1|| mkdir -p ${templates_path}/config/${region}/
    ls -d ${templates_path}/task/${region}/ > /dev/null 2>&1|| mkdir -p ${templates_path}/task/${region}/
    ls -d ${config_path}/${region} > /dev/null 2>&1 || mkdir -p ${config_path}/${region}

    # keep same as remote
    git_sync

    # create template task file
    try "create ${target} template task file"
    if [ ! -e ${templates_path}/task/${region}/${target}.tpl ] ||
        grep "CONTAINER_DEFINITION" ${templates_path}/task/${region}/${target}.tpl > /dev/null 2>&1 ||
        [[ ${run_flag} == 'force' ]] ; then
        \cp ${tpl_path}/task.tpl ${templates_path}/task/${region}/${target}.tpl
        sed -i "s|DEPLOY_TARGET_URI|${deploy_target_uri}|g" ${templates_path}/task/${region}/${target}.tpl
        sed -i "s|CONTAINER_DEFINITION|${container_definition}|g" ${templates_path}/task/${region}/${target}.tpl
        git_pull
        git_commit
        ok
    else
        skip
    fi

}

function consul_template_config_load () {
    try "create ${target} template config file"
    if [ ! -e ${templates_path}/config/${region}/${target}-config.tpl ] ||
        grep "DEPLOY_TARGET_URI" ${templates_path}/config/${region}/${target}-config.tpl > /dev/null 2>&1 ||
        [[ ${run_flag} == 'force' ]]; then
        \cp ${tpl_path}/config.tpl ${templates_path}/config/${region}/${target}-config.tpl
        sed -i "s|DEPLOY_TARGET_URI|${deploy_target_uri}|g" ${templates_path}/config/${region}/${target}-config.tpl
        git_pull
        git_commit
        ok
    else
        skip
    fi
}

function consul_app_config_load () {
    try "update ${target} app config file"
    consul-template -template "${templates_path}/config/${region}/${target}-config.tpl:${config_path}/${region}/${target}.hcl" -vault-renew-token=false -consul-token=${consul_token} -consul-addr=${consul_addr} -once
    if [[ $? -eq 0 ]];then
        ok
    else
        fail
        git_sync
    fi
}

function consul_template_listen () {
    consul-template  -config=${config_path}/${region}/${target}.hcl ${run_mode}
    exit_id=$?
    try "listen on ${target} consul template file"
    if [[ ${exit_id} -eq 0 ]];then
        git_commit
        ok
    else
        fail
        exit 1
    fi
}