resource "aws_lb" "k3s-server-lb" {
  name               = "k3s-server-tcp-lb"
  load_balancer_type = "network"
  internal           = "true"
  subnets            = var.vpc_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-internal-lb")
    }
  )
}

resource "aws_lb_listener" "k3s-server-listener" {
  load_balancer_arn = aws_lb.k3s-server-lb.arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s-server-tg.arn
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-kubeapi-listener")
    }
  )
}

resource "aws_lb_target_group" "k3s-server-tg" {
  port     = var.kube_api_port
  protocol = "TCP"
  vpc_id   = var.vpc_id


  depends_on = [
    aws_lb.k3s-server-lb
  ]

  health_check {
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-internal-lb-tg-kubeapi")
    }
  )
}

resource "aws_autoscaling_attachment" "target" {

  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
    aws_lb_target_group.k3s-server-tg
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.k3s-server-tg.arn
}