resource "aws_iam_role" "this" {
  name = "${var.project_name}-ec2-ssm-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2-ssm-role-${var.environment}"
    }
  )
}

locals {
  secretsmanager_resource_arns = distinct(compact(concat(
    [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.project_name}-mysql-credentials-${var.environment}-*",
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.project_name}-mysql-rotation-${var.environment}-*",
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:rds!db-*",
    ],
    var.secretsmanager_extra_secret_arns,
  )))
}

resource "aws_iam_role_policy" "secretsmanager_get_secret_value" {
  name = "${var.project_name}-ec2-secrets-get-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetSecretValueProjectSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = local.secretsmanager_resource_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_container_builds" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

resource "aws_iam_role_policy" "ecr_push" {
  count = length(var.ecr_repository_arns) > 0 ? 1 : 0

  name = "${var.project_name}-ec2-ecr-push-${var.environment}"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = var.ecr_repository_arns
      },
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-ec2-instance-profile-${var.environment}"
  role = aws_iam_role.this.name
}
