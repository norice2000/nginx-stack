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

variable "key_name" {
  default = "keypair" # The name of your existing key pair in AWS
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#Key pair create and download
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# create keypair to AWS
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh
}

#fetch keypair
resource "local_file" "ec2_keypair" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "/output/${var.key_name}.pem"

  provisioner "local-exec" {
    command = "chmod 400 /output/${var.key_name}.pem"
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    Name = "WebServer"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum update -y",
  #     "sudo yum install -y python3-pip",
  #     "sudo pip3 install ansible",
  #     "ansible --version || echo 'Ansible installation failed'",
  #     "if ! command -v ansible &> /dev/null; then echo 'Ansible is not installed or not in PATH' && exit 1; fi",
  #     "mkdir -p /home/ec2-user/ansible"
  #   ]
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("/root/.ssh/keypair.pem")
  #     host        = self.public_ip
  #   }
  # }

  # provisioner "file" {
  #   source      = "/ansible/"
  #   destination = "/home/ec2-user/ansible"
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("/root/.ssh/keypair.pem")
  #     host        = self.public_ip
  #   }
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "ansible --version",
  #     "echo 'Contents of /home/ec2-user/ansible:'",
  #     "ls -la /home/ec2-user/ansible",
  #     "sudo ansible-playbook /home/ec2-user/ansible/site.yml || echo 'Ansible playbook execution failed'"
  #   ]
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("/root/.ssh/keypair.pem")
  #     host        = self.public_ip
  #   }
  # }
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

output "instance_private_ip" {
  value = aws_instance.web_server.private_ip
}

output "private_key_path" {
  value = "/output/${var.key_name}.pem"
}

output "key_name" {
  value = "${var.key_name}.pem"
}

# Null resource to trigger Ansible
# resource "null_resource" "ansible_provisioner" {
#   depends_on = [aws_instance.web_server]

#   provisioner "local-exec" {
#     command = <<EOT
#       sleep 30;  # Wait for instance to be fully ready
#       echo "${aws_instance.web_server.public_ip}" > inventory;
#       ansible-playbook -i inventory --private-key /root/.ssh/keypair.pem site.yml
#     EOT
#   }
# }