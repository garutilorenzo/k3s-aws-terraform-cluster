locals {
  k3s_tls_san_public     = var.create_extlb && var.expose_kubeapi ? aws_lb.external-lb[0].dns_name : ""
  kubeconfig_secret_name = "kubeconfig-${var.cluster_name}-${var.environment}-v2"
}