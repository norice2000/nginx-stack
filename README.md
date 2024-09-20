# nginx-stack

To get started
1. build docker `docker-compose build`
2. use compose to run terraform
`docker-compose run --rm terraform --version`

The dir structure as follows:
ansible:
- main.yml   <= this is the main file to import tasks or playbook you wish to execute

terraform:
- main.tf provision ec2 resource whilst installing and running ansible playbppl

key
- keypay.pem   <= input your local keypay.pem file to allow ssh identity

aws:
- config   <= populate it like the sample below:

````
[default]
region = us-east-1
output = json
````
- credentials    < AWS Keys

``
[default]
aws_access_key_id = 
aws_secret_access_key = 
``

dont forget to delete the stte file `terraform/.terraform.lock.hcl` when testing
