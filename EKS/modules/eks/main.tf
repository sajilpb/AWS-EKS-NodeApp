module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.aws_eks_cluster_name
  kubernetes_version = "1.34"
  create_kms_key = false
  create_cloudwatch_log_group = false
  enable_irsa = true
  endpoint_public_access = true
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  enable_cluster_creator_admin_permissions = true
  encryption_config = null
  node_iam_role_additional_policies = {
    ecr_access = aws_iam_policy.eks_ecr_policy.arn
  }

   # this will create a general purpose, more faster.
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

########### Role for EKS ###########

data "aws_iam_policy_document" "assume_role_eks" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "eks-policy" {
    statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "elasticloadbalancing:*",
      "ec2:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "eks-ecr" {
  name               = "eks-ecr"
  assume_role_policy = data.aws_iam_policy_document.assume_role_eks.json
}

resource "aws_iam_role_policy" "eks" {
  name   = "eks-node"
  role   = aws_iam_role.eks-ecr.name
  policy = data.aws_iam_policy_document.eks-policy.json
}

resource "aws_iam_policy" "eks_ecr_policy" {
  name        = "EKS-ECR-Access"
  description = "Allow EKS worker nodes to pull images from ECR"
  policy      = data.aws_iam_policy_document.eks-policy.json
}


