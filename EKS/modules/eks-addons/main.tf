resource "aws_iam_role" "ebs_csi_irsa" {
  name = "EKS-EBS-CSI-IRSA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


resource "aws_eks_addon" "ebs_csi" {
  cluster_name              = var.cluster_name
  addon_name                = "aws-ebs-csi-driver"
  addon_version             = "v1.36.0-eksbuild.1" 
  service_account_role_arn  = aws_iam_role.ebs_csi_irsa.arn
}