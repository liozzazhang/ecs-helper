#!/usr/bin/env bash

export LOCAL_DTR=local-dtr.zhihuiya.com
export CN_ECR=xxx
export US_ECR=xxx
export ENV=prod2
export PROFILE
export TEAM_LIST=()

function usage {
cat <<_EOF_

Usage: bash $0 [OPTIONS]

    Options:
        -i image                Docker Image Name, Required.
        -t team                 Team, the same as registry organization, Required.
        -r region               Region, available value is {cn-north-1|us-east-1|all}. Can use short name, {cn|us|all}, Required
        [-a action]             Action for ecr, Optional, {create|update} Default is update.

usage example: bash ecr.sh -i patent_solr:Rel.2.0 -t solr
_EOF_
        exit 1
}

while getopts "i:t:r:a:?h" flag; do
    case $flag in
        i)      image_list=$OPTARG   	        ;;
        t)      team=$OPTARG   	    ;;
        r)      region=$OPTARG	                ;;
        a)      action=$OPTARG                  ;;
        ?|h)    usage                           ;;
    esac
done
shift $((OPTIND-1))

for image in ${image_list[@]}
do
    [[ "Z${image}" == "Z" ]] && echo "[ERROR] image is required!" && usage
done
[[ "Z${team}" == "Z" ]] && echo "[ERROR] team is required!" && usage
[[ "Z${region}" == "Z" ]] && region=all

function tag_image {
    for registry in ${CN_ECR} ${US_ECR};
        do
            if [[  ${LOCAL_DTR} == 'local-dtr.patsnap.com'  ]]; then
                docker tag ${LOCAL_DTR}/patsnap/${image} ${registry}/${team}/${image}
            else
                docker tag ${LOCAL_DTR}/${team}/${image} ${registry}/${team}/${image}
             fi
        done
}

function clean_image {
    for registry in ${LOCAL_DTR} ${CN_ECR} ${US_ECR};
    do
        docker rmi ${registry}/${team}/${image} > /dev/null 2>&1
    done
}

function generate_image {
    docker pull ${LOCAL_DTR}/${team}/${image}
    exit_id=$?
    if [[ ${exit_id} -eq 0 ]]; then
        tag_image
    else
        LOCAL_DTR=dtr.patsnap.com
        docker pull ${LOCAL_DTR}/patsnap/${image}
        __exit_id=$?
        if [[  ${__exit_id} -eq 0 ]]; then
            tag_image
        else
            echo "Image ${image} is not found"
        fi
    fi
}

function push_image {
    while true
    do
        docker push ${ECR}/${team}/${image}
        exit_id=$?
        if [[  ${exit_id} -ne 0  ]]; then
            IFS=':' read -r -a array <<< "${image}"
            image_name=${array[0]}
            repository_name=${team}/${image_name}
            aws ecr list-images --repository-name ${repository_name} > /dev/null 2>&1
            __exit_id=$?
            if [[  ${__exit_id} -eq 0  ]]; then
                echo "failed push to ${region} ECR, please check your network" && exit 1
            else
                aws ecr create-repository --repository-name ${repository_name} && echo "create ${repository_name} successfully"|| break
            fi
        else
            echo "succeed to push image to ${ECR}" && break
        fi
    done
}

function sync2us_image {
    echo
}

case ${region} in
    cn|cn-north-1) for image in ${image_list}; do
            export AWS_PROFILE=cn-north-1_$ENV
            export ECR=${CN_ECR}
            generate_image
            if [[ $? -ne 0 ]];then
                continue
            fi
            push_image
            clean_image
        done
    ;;
    us|us-east-1) for image in ${image_list}; do
            export AWS_PROFILE=us-east-1_$ENV
            export ECR=${US_ECR}
            generate_image
            if [[ $? -ne 0 ]];then
                continue
            fi
            push_image
            clean_image
        done
    ;;
    all) for image in ${image_list}; do
            export AWS_PROFILE=cn-north-1_$ENV
            export ECR=${CN_ECR}
            generate_image
            if [[ $? -ne 0 ]];then
                continue
            fi
            push_image
            export AWS_PROFILE=us-east-1_$ENV
            export ECR=${US_ECR}
            push_image
            clean_image
        done
    ;;
    test|t|tt) for image in ${image_list}; do
            echo $image
          done
          echo $team
          echo $region
    ;;
    *) echo "[ERROR]invalid region!" && usage && exit 1
    ;;
esac