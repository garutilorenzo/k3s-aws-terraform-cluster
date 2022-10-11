resource "aws_security_group" "allow_strict" {
  vpc_id      = var.vpc_id
  name        = "allow-strict"
  description = "security group that allows ssh and all egress traffic"

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-allow-strict")
    }
  )
}

resource "aws_security_group_rule" "ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "ingress_kubeapi" {
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_subnet_cidr]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_http_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_http_port
  to_port           = var.extlb_http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_https_traffic" {
  count             = var.create_extlb ? 1 : 0
  type              = "ingress"
  from_port         = var.extlb_https_port
  to_port           = var.extlb_https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group_rule" "allow_lb_kubeapi_traffic" {
  count             = var.create_extlb && var.expose_kubeapi ? 1 : 0
  type              = "ingress"
  from_port         = var.kube_api_port
  to_port           = var.kube_api_port
  protocol          = "tcp"
  cidr_blocks       = [var.my_public_ip_cidr]
  security_group_id = aws_security_group.allow_strict.id
}

resource "aws_security_group" "efs_sg" {
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

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-efs-sg")
    }
  )
}

resource "aws_security_group" "lambda_sg" {
  vpc_id      = var.vpc_id
  name        = "lambda-security-group"
  description = "Allow lambda function to access kubeapi"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-lambda-sg")
    }
  )
}

resource "aws_security_group" "internal_vpce_sg" {
  vpc_id      = var.vpc_id
  name        = "internal-vpce-sg"
  description = "Allow all traffic trought vpce"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-internal-vpce")
    }
  )
}