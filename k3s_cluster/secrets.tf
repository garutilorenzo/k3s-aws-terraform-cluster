resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name        = local.kubeconfig_secret_name
  description = "Kubeconfig k3s. Cluster name: ${var.cluster_name}, environment: ${var.environment}"
}