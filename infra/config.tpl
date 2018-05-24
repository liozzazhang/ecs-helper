consul {
  address = "consul"
  token = "xxx"
}
vault {
  address = "http://vault"
  token = "xxx"
  renew_token = false
}
template {
  source = "../templates/task/{{ key "DEPLOY_TARGET_URI/deploy/region" }}/{{ key "DEPLOY_TARGET_URI/deploy/target" }}.tpl"

  destination = "../apps/{{ key "DEPLOY_TARGET_URI/deploy/team" }}/{{ key "DEPLOY_TARGET_URI/deploy/project" }}/{{ key "DEPLOY_TARGET_URI/deploy/env" }}/{{ key "DEPLOY_TARGET_URI/deploy/region" }}/task.json"

  command = "jarvis --sync -p {{ key "DEPLOY_TARGET_URI/deploy/project" }} -r {{ key "DEPLOY_TARGET_URI/deploy/region" }} -e {{ key "DEPLOY_TARGET_URI/deploy/env" }} -t {{ key "DEPLOY_TARGET_URI/deploy/tag" }} --details format={{ key "DEPLOY_TARGET_URI/deploy/format" }},file=../apps"

  command_timeout = "3000s"

  error_on_missing_key = true

  perms = 0600

  backup = true

  wait {
    min = "2s"
    max = "10s"
  }
}