{ {{ range ls "DEPLOY_TARGET_URI/task" }}
    "{{ .Key }}": {{ .Value }},{{ end }}
    "containerDefinitions": [
        CONTAINER_DEFINITION
    ]
}