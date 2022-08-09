# HTTP
resource "aws_lb" "external-lb" {
  count              = var.create_extlb ? 1 : 0
  name               = "external-lb"
  load_balancer_type = "network"
  internal           = "false"
  subnets            = var.vpc_subnets

  enable_cross_zone_load_balancing = true

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }

}

resource "aws_lb_listener" "external-lb-listener-http" {
  count             = var.create_extlb ? 1 : 0
  load_balancer_arn = aws_lb.external-lb[count.index].arn

  protocol = "TCP"
  port     = var.extlb_http_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-lb-tg-http[count.index].arn
  }

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }
}

resource "aws_lb_target_group" "external-lb-tg-http" {
  count             = var.create_extlb ? 1 : 0
  port              = var.extlb_http_port
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = true

  depends_on = [
    aws_lb.external-lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }
}

resource "aws_autoscaling_attachment" "target-http" {
  count = var.create_extlb ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k3s_workers_asg,
    aws_lb_target_group.external-lb-tg-http
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external-lb-tg-http[count.index].arn
}

# HTTPS

resource "aws_lb_listener" "external-lb-listener-https" {
  count             = var.create_extlb ? 1 : 0
  load_balancer_arn = aws_lb.external-lb[count.index].arn

  protocol = "TCP"
  port     = var.extlb_https_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-lb-tg-https[count.index].arn
  }

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }
}

resource "aws_lb_target_group" "external-lb-tg-https" {
  count             = var.create_extlb ? 1 : 0
  port              = var.extlb_https_port
  protocol          = "TCP"
  vpc_id            = var.vpc_id
  proxy_protocol_v2 = true

  depends_on = [
    aws_lb.external-lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }

}

resource "aws_autoscaling_attachment" "target-https" {
  count = var.create_extlb ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k3s_workers_asg,
    aws_lb_target_group.external-lb-tg-https
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external-lb-tg-https[count.index].arn
}