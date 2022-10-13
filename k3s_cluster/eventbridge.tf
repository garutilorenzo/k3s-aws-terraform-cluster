### EC2 Spot request interruption warning

resource "aws_cloudwatch_event_rule" "ec2_spot_interruption_warn" {
  name        = "${var.common_prefix}-ec2-spot-interruption-warn-${var.environment}"
  description = "Capture EC2 Spot Interruption warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-spot-interruption-warn-${var.environment}")
    }
  )
}

resource "aws_cloudwatch_event_target" "ec2_spot_interruption_warn_sqs" {
  rule      = aws_cloudwatch_event_rule.ec2_spot_interruption_warn.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.ec2_spot_interruption_warn_queue.arn
}

resource "aws_sqs_queue" "ec2_spot_interruption_warn_queue" {
  name                      = "${var.common_prefix}-ec2-spot-interruption-warn-queue-${var.environment}"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 7200

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-spot-interruption-warn-queue-${var.environment}")
    }
  )
}

resource "aws_sqs_queue_policy" "ec2_spot_interruption_warn_queue_policy" {
  queue_url = aws_sqs_queue.ec2_spot_interruption_warn_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sqs:SendMessage",
        Resource = [
          "${aws_sqs_queue.ec2_spot_interruption_warn_queue.arn}",
          "${aws_cloudwatch_event_rule.ec2_spot_interruption_warn.arn}"
        ]
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          "${aws_lambda_function.kube_cleaner_lambda_function.arn}",
        ]
      }
    ]
  })
}

### EC2 Spot request fulfillment

resource "aws_cloudwatch_event_rule" "ec2_spot_request_fulfillment" {
  name        = "${var.common_prefix}-ec2-spot-fulfillment-${var.environment}"
  description = "Capture EC2 Spot Request Fulfillment"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = ["EC2 Spot Instance Request Fulfillment"]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-spot-fulfillment-${var.environment}")
    }
  )
}

resource "aws_cloudwatch_event_target" "ec2_spot_request_fulfillment_sqs" {
  rule      = aws_cloudwatch_event_rule.ec2_spot_request_fulfillment.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.ec2_spot_request_fulfillment_queue.arn
}

resource "aws_sqs_queue" "ec2_spot_request_fulfillment_queue" {
  name                      = "${var.common_prefix}-ec2-spot-fulfillment-queue-${var.environment}"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 7200

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-spot-fulfillment-queue-${var.environment}")
    }
  )
}

resource "aws_sqs_queue_policy" "ec2_spot_request_fulfillment_queue_policy" {
  queue_url = aws_sqs_queue.ec2_spot_request_fulfillment_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sqs:SendMessage",
        Resource = [
          "${aws_sqs_queue.ec2_spot_request_fulfillment_queue.arn}",
          "${aws_cloudwatch_event_rule.ec2_spot_request_fulfillment.arn}"
        ]
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          "${aws_lambda_function.kube_cleaner_lambda_function.arn}",
        ]
      }
    ]
  })
}