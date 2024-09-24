#!/bin/bash

# Run Terraform
docker-compose run --rm terraform init
docker-compose run --rm terraform apply -auto-approve

# Extract key name and public IP from Terraform output
KEY_NAME=$(docker-compose run --rm terraform output -raw key_name)
PUBLIC_IP=$(docker-compose run --rm terraform output -raw instance_public_ip)

# Display the extracted values (for verification)
echo "Key Name: $KEY_NAME"
echo "Public IP: $PUBLIC_IP"

# Debug: Check if the key file exists
docker-compose run --rm ansible ls -l /output

# Ensure the key file has the correct permissions
chmod 600 ./output/$KEY_NAME

# Run Ansible
docker-compose run --rm \
  -e KEY_NAME=$KEY_NAME \
  -e PUBLIC_IP=$PUBLIC_IP \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  ansible ansible-playbook \
  -i "$PUBLIC_IP," \
  --private-key=/output/$KEY_NAME \
  -u ec2-user \
  /ansible/site.yml

echo "Ansible playbook execution completed."