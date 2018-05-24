#!/usr/bin/env bash

function helper {
cat <<_EOF_

$0      -p project -r region -e env

        -r region               Region, required. Only supports 'local, cn-north-1, and us-east-1'
        -e env                  Env, required.
        -p project              Project name(w-analytics), required


usage example: sh $0 -p w-insights -r cn -e release
_EOF_
}

while getopts "p:e:r:?h" flag; do
    case $flag in
        p)      project=$OPTARG   	        ;;
        r)      region=$OPTARG   	                ;;
        e)      env=$OPTARG                       ;;
        ?|h)    usage                             ;;
    esac
done


function parameter_handler {
    env_local=(ci qa st dev qa2)
    region_list=(local cn-north-1 us-east-1)
    consul_master=xxx
    consul_token=xxx

    # original/local
    skeleton_file=../infra/skeleton.txt

    project_tmp=${project#*-}
    team=${project_tmp%%-*}
    name=\"${project}\"
    deploy_target_uri=${project}/${region}/${env}/${env_type}
    target=${project}-${env}
    taskRoleArn=\"ecs-task-${project}-role\"
    volumes="[{\"host\": {\"sourcePath\": \"/mnt/data/${project}\"}, \"name\": \"data-vol\"}, {\"host\": {\"sourcePath\": \"/mnt/logs/${project}\"}, \"name\": \"logs-vol\"}, {\"host\": {\"sourcePath\": \"/mnt/main/${project}\"}, \"name\": \"main-vol\"}, {\"host\": {\"sourcePath\": \"/root/vault\"}, \"name\": \"credential-vol\"}]"

    if [[ 'Z'${project} == 'Z' ]];then
        echo "target role is required" && helper
    else
        echo ${project} | grep '^[sw]' > /dev/null 2>&1|| helper
    fi
    [[ 'Z'${region} == 'Z' ]] && echo "region is required" && helper
    [[ 'Z'${env} == 'Z' ]] && echo "env is required" && helper
    case ${region} in
    cn|cn-north-1) region=cn-north-1    ;;
    us|us-east-1)  region=us-east-1     ;;
    local)         region=local         ;;
    *)             echo "Invalid region input" && helper    ;;
    esac
}

function register_handler {
    consul_path=Microservices/${team}/${project}/${env}/${region}

    # grep all parameters exclude commented ones
    keys=(`grep '=' ${skeleton_file} | grep -v ^# | awk -F '=' '{print $1}'`)

    #values=(`grep http ${project} | awk -F '=' '{print $2}' | awk -F '/' '{print $3}' `)
    keys_lenth=${#keys[@]}

    # check if project is empty
    echo "Checking if the project is empty"
    j=0
    while [[ ${j} -lt ${keys_lenth} ]]; do
        consul_value=`consul kv get --http-addr=${consul_master} -token=${consul_token} "${consul_path}/${keys[$j]}" 2>/dev/null`
        if [[ ${consul_value} != '' ]];then
            echo "This project you initialized is not empty(${keys[$j]}=${consul_value})! Create skeleton parameter structure failed"
            echo "please check with your project name or clean the project(${consul_path}) in consul!"
            exit 1
        fi
        j=$[${j}+1]
    done

    echo "** start generate project consul skeleton **"
    echo "******************************************************"

    while [[ ${i} -lt ${keys_lenth} ]]; do
        retry_times=1
        while [[ ${retry_times} -le 5 ]]; do
            value=$(grep ^"${keys[$i]}" ${skeleton_file} | awk -F '=' '{print $2}')
            if [[ 'Z'${value} == 'Z' ]];then
                value_tmp[0]=$(echo ${keys[$i]} | awk -F '/' '{print $NF}')
                value=$(eval echo '$'"${value_tmp[0]}")
            fi
            echo "${keys[$i]}=${value}"
            consul kv put --http-addr=${consul_master} -token=${consul_token} "${consul_path}/${keys[$i]}" "${value}"
            if [[ $? != 0 ]];then
                echo "${retry_times} tries failed"
                retry_times=$[${retry_times}+1]
                sleep 7s
            else
                break
            fi
        done
        i=$[$i+1]
    done

    ## application parameters
    consul kv put --http-addr=${consul_master} -token=${consul_token} "${consul_path}/environment/"
}

parameter_handler

register_handler
