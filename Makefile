# Makefile

## Build
build:
	docker-compose build --no-cache
.PHONY: build

### Terraform
init: 
	docker-compose run --rm terraform init
.PHONY: init

test: init
	docker-compose run --rm terraform test
.PHONY: test

fmt: fmt
	docker-compose run --rm terraform fmt -recursive .
.PHONY: fmt

lint: init
	docker-compose run --rm tflint --recursive
.PHONY: lint

plan: init
	docker-compose run --rm terraform plan
.PHONY: plan

apply: init
	docker-compose run --rm terraform apply -auto-approve
.PHONY: apply

destroy: init
	docker-compose run --rm terraform destroy --auto-approve
.PHONY: destroy

### Ansible
# Define variables to store the outputs from Terraform
KEY_NAME := $(shell docker-compose run --rm terraform output -raw key_name)
PUBLIC_IP := $(shell docker-compose run --rm terraform output -raw instance_public_ip)

# Display the extracted values (for verification)
display:
	@echo "Key Name: $(KEY_NAME)"
	@echo "Public IP: $(PUBLIC_IP)"

# Run Ansible & define variables from terraform output
run_ansible:
	$(eval KEY_NAME := $(shell docker-compose run --rm terraform output -raw key_name))
	$(eval PUBLIC_IP := $(shell docker-compose run --rm terraform output -raw instance_public_ip))
	docker-compose run --rm \
		-e KEY_NAME=$(KEY_NAME) \
      	-e PUBLIC_IP=$(PUBLIC_IP) \
      	-e ANSIBLE_HOST_KEY_CHECKING=False \
      	ansible ansible-playbook \
      	-i "$(PUBLIC_IP)," \
      	--private-key=/output/$(KEY_NAME) \
      	-u ec2-user \
      	/ansible/site.yml

# Run deploy
deploy: init apply run_ansible
.PHONY: deploy