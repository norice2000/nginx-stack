terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0ebfd941bbafe70c6" # Amazon Linux 2023 AMI ID for us-east-1
}

variable "key_name" {
  default = "keypair" # The name of your existing key pair in AWS
}

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    Name = "WebServer"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y python3-pip",
      "sudo pip3 install ansible",
      "ansible --version || echo 'Ansible installation failed'",
      "if ! command -v ansible &> /dev/null; then echo 'Ansible is not installed or not in PATH' && exit 1; fi",
      "mkdir -p /home/ec2-user/ansible"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/root/.ssh/keypair.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "/ansible/"
    destination = "/home/ec2-user/ansible"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/root/.ssh/keypair.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ansible --version",
      "echo 'Contents of /home/ec2-user/ansible:'",
      "ls -la /home/ec2-user/ansible",
      "ansible-playbook /home/ec2-user/ansible/main.yml || echo 'Ansible playbook execution failed'"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/root/.ssh/keypair.pem")
      host        = self.public_ip
    }
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

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}