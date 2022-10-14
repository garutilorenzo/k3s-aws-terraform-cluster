resource "aws_efs_file_system" "k3s_persistent_storage" {
  count          = var.efs_persistent_storage ? 1 : 0
  creation_token = "${var.common_prefix}-efs-persistent-storage-${var.environment}"
  encrypted      = true

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-efs-persistent-storage-${var.environment}")
    }
  )
}

resource "aws_efs_mount_target" "k3s_persistent_storage_mount_target" {
  count           = var.efs_persistent_storage ? length(var.vpc_subnets) : 0
  file_system_id  = aws_efs_file_system.k3s_persistent_storage[0].id
  subnet_id       = var.vpc_subnets[count.index]
  security_groups = [aws_security_group.efs_sg[0].id]
}