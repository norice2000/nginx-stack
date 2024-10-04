terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  #region = ap-southeast-2
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "s3-bucket-statefile"
    key    = "test/nginx-stack.tfstate"
    #region = ap-southeast-2
    region = "us-east-1"
  }
}

variable "region" {
  #default = "ap-southeast-2"
  default = "us-east-1"
}

# variable "vpc_id" {
#   description = "The ID of the VPC"
#   default     = "vpc-0d7466ab4daddd433"
# }

variable "subnet_id" {
  description = "The ID of the subnet"
  default     = "subnet-0e2282d8f458ae0bf"
  #default     = "subnet-082196bccfdd34fe3"
}

variable "aws_security_group_id" {
  description = "The ID of the Security Group"
  default     = "sg-02653ef7928a7ba7b"
}

variable "key_name" {
  default = "ssh_key_test1"
}

data "aws_ami" "image_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Store SSH key in Secrets Manager (JSON format)
resource "aws_secretsmanager_secret" "ssh_key" {
  name = var.key_name
}

# Create entry in secrets manager
resource "aws_secretsmanager_secret_version" "ssh_key" {
  secret_id = aws_secretsmanager_secret.ssh_key.id
  secret_string = jsonencode({
    key_name    = aws_key_pair.generated_key.key_name
    private_key = tls_private_key.ssh_key.private_key_pem
  })
}

# provision ec2
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.image_ami.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id] 
  subnet_id              = var.subnet_id

  tags = {
    Name = "ec2-nginx"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#outputs
output "instance_id" {
  value       = aws_instance.web_server.id
  description = "Instance ID needed for SSM"
}

output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Required to create Ansible Inventory"
}

output "instance_private_ip" {
  value       = aws_instance.web_server.private_ip
  description = "Required to create Ansible Inventory"
}

output "ssh_key_secret_name" {
  value       = aws_secretsmanager_secret.ssh_key.name
  description = "Name of the secret containing the SSH key"
}