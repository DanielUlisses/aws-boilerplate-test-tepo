.PHONY: help

help:
	@echo 'Usage: make <target>'
	@echo ''
	@echo 'Targets:'
	@echo ''
	@echo '    all_pipeline_config        Configure the AWS devops pipelines deployment'
	@echo '    prod_pipeline_config       Configure the AWS devops pipelines deployment for prod environment'
	@echo ''
	@echo '    prod_config                Configure, Prod AWS build deployment'
	@echo ''
	@echo '    prod_build                 Configure & Run, Prod AWS build deployment'
	@echo '    prod_build_config          Configure, Prod AWS build deployment'
	@echo '    prod_build_test            Run, Prod AWS build deployment'
	@echo ''
	@echo '    prod_dataprocess           Configure & Run, Prod AWS dataprocess deployment'
	@echo '    prod_dataprocess_config    Configure, Prod AWS dataprocess deployment'
	@echo '    prod_dataprocess_test      Run, Prod AWS dataprocess deployment'
	@echo ''
	@echo '    prod_datawarehouse         Configure & Run, Prod AWS datawarehouse deployment'
	@echo '    prod_datawarehouse_config  Configure, Prod AWS datawarehouse deployment'
	@echo '    prod_datawarehouse_test    Run, Prod AWS datawarehouse deployment'
	@echo ''
	@echo '    help                       Show this help'
	@echo ''
	@echo '    module_test                Example to devnstrate a module-specific test'
	@echo ''
	@echo '    update_modules_doc         Format ALL .tf and updates README.md files from local modules'
	@echo ''

.PHONY: all_pipelines_config

all_pipelines_config: prod_pipeline_config

.PHONY: prod_pipeline_config

prod_pipeline_config:
	@echo Configuring AWS Devops build pipelines...
	@cd ../build; chmod +x scripts/configure.sh; ./scripts/configure.sh -c true -e prod

.PHONY: prod_config

prod_config: prod_build_config prod_dataprocess_config prod_datawarehouse_config

.PHONY: prod_build

prod_build: prod_build_config prod_build_test

.PHONY: prod_dataprocess

prod_dataprocess: prod_dataprocess_config prod_dataprocess_test

.PHONY: prod_datawarehouse

prod_datawarehouse: prod_datawarehouse_config prod_datawarehouse_test

.PHONY: prod_build_config

prod_build_config:
	@echo Cleaning-up Terragrunt cache directories...
	@cd build; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .
	@echo Configuring prod build environment...
	@cd build; chmod +x scripts/configure.sh; ./scripts/configure.sh -a "arn:aws:iam::555091451601:user/ulisses" -e prod -i 555091451601

.PHONY: prod_build_test

prod_build_test:
	@echo Running prod build integration tests...
	@cd build/test; go mod init terragrunt_deployment_test.go && go mod tidy; go test -v -timeout 60m
	@echo Cleaning-up Terragrunt cache directories after deploy...
	@cd build; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .

.PHONY: prod_dataprocess_config

prod_dataprocess_config:
	@echo Cleaning-up Terragrunt cache directories...
	@cd dataprocess; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .
	@echo Configuring prod dataprocess environment...
	@cd dataprocess; chmod +x scripts/configure.sh; ./scripts/configure.sh -a "arn:aws:iam::555091451601:user/ulisses" -e prod -i 555091451601

.PHONY: prod_dataprocess_test

prod_dataprocess_test:
	@echo Running prod dataprocess integration tests...
	@cd dataprocess/test; go mod init terragrunt_deployment_test.go && go mod tidy; go test -v -timeout 60m
	@echo Cleaning-up Terragrunt cache directories after deploy...
	@cd dataprocess; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .

.PHONY: prod_datawarehouse_config

prod_datawarehouse_config:
	@echo Cleaning-up Terragrunt cache directories...
	@cd datawarehouse; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .
	@echo Configuring prod datawarehouse environment...
	@cd datawarehouse; chmod +x scripts/configure.sh; ./scripts/configure.sh -a "arn:aws:iam::555091451601:user/ulisses" -e prod -i 555091451601

.PHONY: prod_datawarehouse_test

prod_datawarehouse_test:
	@echo Running prod datawarehouse integration tests...
	@cd datawarehouse/test; go mod init terragrunt_deployment_test.go && go mod tidy; go test -v -timeout 60m
	@echo Cleaning-up Terragrunt cache directories after deploy...
	@cd datawarehouse; chmod +x ../../scripts/prune_terragrunt_cache.sh && ../../scripts/prune_terragrunt_cache.sh .

.PHONY: module_test

module_test:
	@echo Running module unit test from template...
	@cd build/templates/test; go mod init terragrunt_module_test.go && go mod tidy; go test -v -moddir="../../reg-primary/s3-buckets/state"

.PHONY: update_modules_doc

update_modules_doc:
	@echo Running pre-commit hook to update modules documentation...
	@cd ../../; pre-commit run -a
