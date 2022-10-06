resource "aws_security_group" "allow-strict" {
  vpc_id      = var.vpc_id
  name        = "allow-strict"
  description = "security group that allows ssh and all egress traffic"

  tags = {
    Name        = "allow-strict"
    environment = "${var.environment}"
    provisioner = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "ingress_kubeapi" {
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_subnet_cidr]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "allow_lb_http_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_http_port
  to_port           = var.extlb_http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "allow_lb_https_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_https_port
  to_port           = var.extlb_https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group_rule" "allow_lb_kubeapi_traffic" {
  count             = var.create_extlb && var.expose_kubeapi ? 1 : 0
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr]
  security_group_id = aws_security_group.allow-strict.id
}

resource "aws_security_group" "efs-sg" {
  vpc_id      = var.vpc_id
  name        = "efs-security-group"
  description = "Allow EFS access from VPC subnets"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }
}