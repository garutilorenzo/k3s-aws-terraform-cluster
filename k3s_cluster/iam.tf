resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = var.default_instance_profile_name
  role = aws_iam_role.aws_ec2_custom_role.name

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }

}

resource "aws_iam_role" "aws_ec2_custom_role" {
  name = var.default_iam_role

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

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }

}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "ClusterAutoscalerPolicy"
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

  tags = {
    environment = "${var.environment}"
    provisioner = "terraform"
  }
}

resource "aws_iam_policy" "aws_efs_csi_driver_policy" {
  name        = "AwsEfsCsiDriverPolicy"
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
            "aws:ResourceTag/efs.csi.aws.com/cluster" : "true"
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
            "aws:ResourceTag/efs.csi.aws.com/cluster" : "true"
          }
        }
      },
    ]
  })
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

resource "aws_iam_role_policy_attachment" "attach_aws_efs_csi_driver_policy_policy" {
  role       = aws_iam_role.aws_ec2_custom_role.name
  policy_arn = aws_iam_policy.aws_efs_csi_driver_policy.arn
}