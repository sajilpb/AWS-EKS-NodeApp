
resource "aws_codebuild_project" "project" {
  name          = var.Codebuild-project-name
  description   = var.Codebuild-project-name-description
  build_timeout = 5
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "Java-group"
      stream_name = "Java-stream"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.Source-repo
    buildspec       = var.source-buildspec-file
    git_clone_depth = 1
  }

  source_version = var.source-branch

  tags = {
    Environment = var.Codebuild-project-name
  }
}

########### Role for Codebuild ###########

data "aws_iam_policy_document" "assume_role_codebuild" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "eks:*"
    ]

    resources = ["*"]
  }

   statement {
    effect = "Allow"

    actions = [
      "ecr:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild-java"
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.policy_codebuild.json
}

resource "aws_iam_role" "codebuild" {
  name               = "Codebuild-java"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}
