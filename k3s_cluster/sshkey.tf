resource "aws_key_pair" "my_ssh_public_key" {
  key_name   = "my_ssh_public_key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${local.common_prefix}-ssh-pubkey")
    }
  )
}