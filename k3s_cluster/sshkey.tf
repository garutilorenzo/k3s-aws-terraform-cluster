resource "aws_key_pair" "my_ssh_public_key" {
  key_name   = "${var.common_prefix}-ssh-pubkey-${var.environment}"
  public_key = file(var.PATH_TO_PUBLIC_KEY)

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ssh-pubkey-${var.environment}")
    }
  )
}