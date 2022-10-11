locals {
  k3s_tls_san_public     = var.create_extlb && var.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name = "kubeconfig-${var.cluster_name}-${var.environment}-v2"
  global_tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k3s-aws-terraform-cluster"
  }
  common_prefix = "${var.cluster_name}-${var.environment}"
}