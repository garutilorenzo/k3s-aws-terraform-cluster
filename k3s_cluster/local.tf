locals {
  k3s_tls_san_public     = var.create_extlb && var.expose_kubeapi ? aws_lb.external_lb[0].dns_name : ""
  kubeconfig_secret_name = "${var.common_prefix}-kubeconfig-${var.cluster_name}-${var.environment}-v2"
  global_tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k3s-aws-terraform-cluster"
    k3s_cluster_name = "${var.cluster_name}"
    application      = "k3s"
  }
}