# Makefile build-in parameters
py=python
shell=bash
ecs=aws ecs
ecs_path=inventory/
#ecs_deploy=ecs.py
ecs_registor=kv_registor.py
ecs_skeleton=skeleton.sh
ecs_generate_handler=generate_ecs.sh
# User defined parameters
ifdef tags
   service_tag:=${tags}
endif

ifeq ($(region),cn-north-1)
   static_region='cn'
endif

ifeq (${region},'us-east-1')
   static_region='us'
endif

ifeq ($(mode),force)
   deploy_mode:='-f'
endif
get_family_prefix = \
	$(addsuffix -release,$1)

get_task_definition = \
	$(shell ${ecs} list-task-definition-families --family-prefix $(call get_family_prefix,$1) \
	--output text --status ACTIVE --profile ${region}_${env} |cut -f 2)

valid-check: check-region check-env

# register apps/tar_role-*/task.json to consul
ecs-register-%:: valid-check
	@cd ${ecs_path} && ${py} ${ecs_registor} -p $(subst ecs-register-,,$@) -e ${env} -r ${region} -t ecs

# generate new project skeleton
ecs-skeleton-%:: valid-check
	@cd ${ecs_path} && ${shell} ${ecs_skeleton} -p $(subst ecs-skeleton-,,$@) -e ${env} -r ${region}

# update task-definition and service
ecs-update-%:: valid-check
	@jarvis -p $(subst ecs-update-,,$@) -e ${env} -r ${region} -t ecs --details file=apps

# ecs handler
ecs-handler-%:: valid-check setup
	@cd ${ecs_path} && ${shell} ${ecs_generate_handler} -p $(subst ecs-handler-,,$@) -e ${env} -r ${region} -o ${deploy_mode}

# ecr sync
ecs-ecr-sync:: check-region
	@cd ${ecs_path} && ${shell} ecr.sh -i "${image}" -t ${team} -r ${region}

