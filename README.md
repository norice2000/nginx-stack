# nginx-stack

To get started
1. have an env variable exported:
```
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_DEFAULT_REGION=your_default_region
```
1. build docker `docker-compose build`
2. use compose to run terraform
`docker-compose run --rm terraform --version`

The dir structure as follows:
ansible:
- main.yml   <= this is the main file to import tasks or playbook you wish to execute

terraform:
- main.tf provision ec2 resource whilst installing and running ansible playbppl

key
- keypay.pem   <= input your local keypay.pem file to allow ssh identity, remember to make it chmod 400

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
