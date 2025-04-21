provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "vishal-strapi-app" {
  ami           = "aami-084568db4383264d4"
  instance_type = "t2.medium"
  key_name      = "strapi-ec2-key"

  user_data = <<-EOF
              #!/bin/bash
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_registry}
              docker pull ${var.ecr_registry}/strapi-app:${var.image_tag}
              docker run -d -p 1337:1337 ${var.ecr_registry}/strapi-app:${var.image_tag}
              EOF

  security_groups = [aws_security_group.strapi_sg.name]
}

resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg"

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
