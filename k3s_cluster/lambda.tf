resource "aws_lambda_function" "kube_cleaner_lambda_function" {
  function_name    = "${var.common_prefix}-kube-cleaner-${var.environment}"
  filename         = "${path.module}/lambda/kube_cleaner.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/kube_cleaner.zip")
  handler          = "lambda.lambda_handler"
  runtime          = "python3.9"
  timeout          = 5
  memory_size      = 128

  vpc_config {
    subnet_ids         = var.vpc_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  role = aws_iam_role.kube_cleaner_lambda_role.arn

  environment {
    variables = {
      KUBECONFIG_SECRET_NAME = local.kubeconfig_secret_name
      INFO_LOGGING           = "false"
      DEBUG                  = "false"
    }
  }

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kube-cleaner-${var.environment}")
    }
  )
}

resource "aws_lambda_event_source_mapping" "trigger_lambda_on_ec2_interruption" {
  event_source_arn = aws_sqs_queue.ec2_spot_interruption_warn_queue.arn
  function_name    = aws_lambda_function.kube_cleaner_lambda_function.arn
}