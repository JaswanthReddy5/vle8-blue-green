# VLE-8: Blue-Green Deployment - AWS infrastructure
# Phase 1: EC2 host for Jenkins + Docker + kubectl + Minikube (region per handout: ap-south-1)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Current Ubuntu 22.04 LTS AMI, resolved dynamically via the official Canonical SSM
# parameter (the handout's "ami-0abcdef12345" is a placeholder, not a real AMI).
data "aws_ssm_parameter" "ubuntu_2204" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

resource "aws_security_group" "jenkins_sg" {
  name        = "vle8-bluegreen-sg"
  description = "VLE-8: SSH (restricted) + Jenkins + app port"

  ingress {
    description = "SSH from my current IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "SSH from AWS EC2 Instance Connect (ap-south-1) - local network blocks outbound 22 directly"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.eic_cidr]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App (blue/green service)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App NodePort range (minikube service)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vle8-bluegreen-sg"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ssm_parameter.ubuntu_2204.value
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "VLE8-BlueGreen-Server"
  }
}

resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
    [bluegreen]
    server1 ansible_host=${aws_instance.jenkins.public_ip}

    [bluegreen:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath("${path.module}/${var.key_name}.pem")}
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
