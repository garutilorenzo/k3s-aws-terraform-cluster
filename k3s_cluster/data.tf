data "aws_iam_policy" "AmazonEC2ReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "aws_instances" "k3s_servers" {

  depends_on = [
    aws_autoscaling_group.k3s_servers_asg,
  ]

  instance_tags = {
    k3s-instance-type = "k3s-server"
    provisioner       = "terraform"
    environment       = var.environment
  }

  instance_state_names = ["running"]
}

data "aws_instances" "k3s_workers" {

  depends_on = [
    aws_autoscaling_group.k3s_workers_asg,
  ]

  instance_tags = {
    k3s-instance-type = "k3s-worker"
    provisioner       = "terraform"
    environment       = var.environment
  }

  instance_state_names = ["running"]
}

data "template_cloudinit_config" "k3s_server" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/k3s-install-server.sh", { k3s_token = var.k3s_token, is_k3s_server = true, k3s_url = aws_lb.k3s-server-lb.dns_name, k3s_tls_san = aws_lb.k3s-server-lb.dns_name })
  }
}

data "template_cloudinit_config" "k3s_agent" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/k3s-install-agent.sh", { k3s_token = var.k3s_token, is_k3s_server = false, k3s_url = aws_lb.k3s-server-lb.dns_name, k3s_tls_san = aws_lb.k3s-server-lb.dns_name })
  }
}