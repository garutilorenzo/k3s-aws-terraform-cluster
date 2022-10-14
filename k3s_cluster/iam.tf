resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.common_prefix}-ec2-instance-profile-${var.environment}"
  role = aws_iam_role.aws_ec2_custom_role.name

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-instance-profile-${var.environment}")
    }
  )
}

resource "aws_iam_role" "aws_ec2_custom_role" {
  name = "${var.common_prefix}-ec2-custom-iam-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-ec2-custom-iam-role-${var.environment}")
    }
  )

}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.common_prefix}-cluster-autoscaler-policy-${var.environment}"
  path        = "/"
  description = "Cluster autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:DescribeTags",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-cluster-autoscaler-policy-${var.environment}")
    }
  )
}

resource "aws_iam_policy" "aws_efs_csi_driver_policy" {
  name        = "${var.common_prefix}-csi-driver-policy-${var.environment}"
  path        = "/"
  description = "AWS EFS CSI driver policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeAvailabilityZones"
        ],
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint"
        ],
        Resource = [
          "*"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-csi-driver-policy-${var.environment}")
    }
  )
}


resource "aws_iam_policy" "allow_secrets_manager" {
  name        = "${var.common_prefix}-secrets-manager-policy-${var.environment}"
  path        = "/"
  description = "Secrets Manager Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-secrets-manager-policy-${var.environment}")
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_ec2_ro_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ReadOnlyAccess.arn
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_role_policy_attachment" "attach_cluster_autoscaler_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_iam_role_policy_attachment" "attach_aws_efs_csi_driver_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = aws_iam_policy.aws_efs_csi_driver_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_allow_secrets_manager_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = aws_iam_policy.allow_secrets_manager.arn
}

## Lambda

resource "aws_iam_role" "kube_cleaner_lambda_role" {
  name               = "${var.common_prefix}-kube-cleaner-iam-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kube-cleaner-iam-role-${var.environment}")
    }
  )
}

resource "aws_iam_role_policy_attachment" "kube_cleaner_lambda_attachment" {
  role       = aws_iam_role.kube_cleaner_lambda_role.name
  policy_arn = aws_iam_policy.kube_cleaner_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_vpc_policy" {
  role       = aws_iam_role.kube_cleaner_lambda_role.name
  policy_arn = data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn
}

resource "aws_iam_policy" "kube_cleaner_lambda_policy" {
  name        = "${var.common_prefix}-kube-cleaner-policy-${var.environment}"
  description = "Policy for kube_cleaner_lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })

  tags = merge(
    local.global_tags,
    {
      "Name" = lower("${var.common_prefix}-kube-cleaner-policy-${var.environment}")
    }
  )
}