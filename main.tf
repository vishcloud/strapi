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
resource "aws_security_group" "vishalp_strapi_sg" {
  name        = "vishalp-strapi-security-group"
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
    Name = "vishal_strapi_sg"
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
  vpc_security_group_ids = [aws_security_group.vishalp_strapi_sg.id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  # Removed `security_groups` attribute because it conflicts with `vpc_security_group_ids`
  # Use only `vpc_security_group_ids` for instances in a VPC

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              
              # Update system
              apt-get update -y
              
              # Install required packages
              apt-get install -y \
                  unzip \
                  apt-transport-https \
                  ca-certificates \
                  curl \
                  gnupg \
                  lsb-release
              
              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              
              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              # Configure Docker permissions
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              
              # Login to ECR
              aws ecr get-login-password --region us-east-1 | \
              docker login --username AWS --password-stdin ${var.ecr_registry}
              
              # Run container with restart policy
              docker run -d \
                --restart unless-stopped \
                -p 1337:1337 \
                --name strapi \
                ${var.ecr_registry}/${var.image_name}:${var.image_tag}
              
              # Verify container status
              sleep 10
              docker ps --filter "name=strapi"
              EOF

  tags = {
    Name = "vishal_strapi_server"
  }

  depends_on = [aws_security_group.vishalp_strapi_sg]
}
