resource "aws_security_group" "allow-strict" {
  vpc_id      = var.vpc_id
  name        = "allow-strict"
  description = "security group that allows ssh and all egress traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip_cidr]
  }

  ingress {
    from_port   = var.kube_api_port
    to_port     = var.kube_api_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }


  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = {
    Name = "allow-strict"
  }
}