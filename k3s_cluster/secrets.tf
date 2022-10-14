resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name        = local.kubeconfig_secret_name
  description = "Kubeconfig k3s. Cluster name: ${var.cluster_name}, environment: ${var.environment}"

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.kubeconfig_secret_name}")
    }
  )
}