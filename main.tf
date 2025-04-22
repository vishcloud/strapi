provider "aws" {
  region = "us-east-1"
}

variable "image_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "ecr_registry" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.medium" # You can set a default or require input
}

variable "ssh_key_name" {
  type = string
}

# Security group for Strapi EC2 instance
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-security-group"
  description = "Security group for Strapi application"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Strapi default port
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-sg"
  }
}

# Get latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance for Strapi
resource "aws_instance" "vishal_strapi_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  # Removed `security_groups` attribute because it conflicts with `vpc_security_group_ids`
  # Use only `vpc_security_group_ids` for instances in a VPC

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker if not installed
              if ! command -v docker &> /dev/null; then
                apt-get update
                apt-get install -y docker.io
                systemctl start docker
                systemctl enable docker
              fi

              # Login to AWS ECR
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_registry}

              # Pull and run the Docker container
              docker pull ${var.ecr_registry}/${var.image_name}:${var.image_tag}
              docker run -d -p 1337:1337 ${var.ecr_registry}/${var.image_name}:${var.image_tag}
              EOF

  tags = {
    Name = "vishal_strapi_server"
  }

  depends_on = [aws_security_group.strapi_sg]
}
