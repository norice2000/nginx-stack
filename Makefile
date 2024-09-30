# Makefile

## Build
build:
	docker-compose build --no-cache
.PHONY: build

### Terraform
## Initialise
init:
	docker-compose run --rm terraform init
.PHONY: init

## Workspace
workspace:
	docker-compose run --rm terraform-utils sh -c 'cd $(TERRAFORM_ROOT_MODULE); terraform workspace select $(TERRAFORM_WORKSPACE) || terraform workspace new $(TERRAFORM_WORKSPACE)'
.PHONY: workspace

## Plan
plan:
	docker-compose run --rm terraform plan
.PHONY: plan
# plan: init workspace
# 	docker-compose run --rm terraform-utils sh -c 'cd ${TERRAFORM_ROOT_MODULE}; terraform plan'
# .PHONY: plan

## Apply
apply:
	docker-compose run --rm terraform apply -auto-approve
.PHONY: apply
# apply: init workspace
# 	docker-compose run --rm terraform-utils sh -c 'cd ${TERRAFORM_ROOT_MODULE}; terraform apply'
# .PHONY: apply

## Destroy
destroy:
	docker-compose run --rm terraform destroy --auto-approve
.PHONY: destroy
# destroy: init workspace
# 	docker-compose run --rm terraform-utils sh -c 'cd ${TERRAFORM_ROOT_MODULE}; terraform destroy'
# .PHONY: destroy

### Ansible
