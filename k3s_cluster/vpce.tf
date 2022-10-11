resource "aws_vpc_endpoint" "vpce_secretsmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.AWS_REGION}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.vpc_subnets
  security_group_ids = [
    aws_security_group.internal-vpce-sg.id,
  ]

  private_dns_enabled = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-secretsmanager-vpce")
    }
  )
}