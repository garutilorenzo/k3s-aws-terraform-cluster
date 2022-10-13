# Ref. https://github.com/hashicorp/terraform-provider-aws/issues/10329
resource "null_resource" "assign_default_sg" {
  triggers = {
    lambda_sg = aws_security_group.lambda_sg.id
    vpc_id    = var.vpc_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "/bin/bash ${path.module}/files/update-lambda-sg.sh ${self.triggers.vpc_id} ${self.triggers.lambda_sg}"
  }
}