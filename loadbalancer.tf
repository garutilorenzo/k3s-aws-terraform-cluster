resource "aws_lb" "k3s-server-lb" {
  name               = "k3s-server-tcp-lb"
  load_balancer_type = "network"
  internal           = "true"
  subnets            = var.vpc_subnets

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "k3s-server-listener" {
  load_balancer_arn = aws_lb.k3s-server-lb.arn

  protocol = "TCP"
  port     = 6443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s-server-tg.arn
  }
}

resource "aws_lb_target_group" "k3s-server-tg" {
  port     = 6443
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
}

resource "aws_autoscaling_attachment" "target" {

  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
    aws_lb_target_group.k3s-server-tg
  ]

  autoscaling_group_name = aws_autoscaling_group.k3s_servers_asg.name
  alb_target_group_arn   = aws_lb_target_group.k3s-server-tg.arn
}