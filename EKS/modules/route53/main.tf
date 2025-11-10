# create a iam policy for Service Account to access 53

resource "aws_iam_policy" "external_dns" {
  name        = "external-dns-policy"
  description = "Policy for ExternalDNS to manage Route 53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

# create iam role for external dns
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

resource "aws_iam_role" "external_dns" {
  name = "AmazonEKSExternalDNSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}


# Install external DNS
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.15.0"

  set = [
    {
    name  = "provider"
    value = "aws"
    },
    {
    name  = "policy"
    value = "sync"
    },
    {
    name  = "registry"
    value = "txt"
    },
    {
    name  = "txtOwnerId"
    value = "eks-lab"
    },
    {
    name  = "aws.zoneType"
    value = "public"
    },
    {
    name  = "domainFilters[0]"
    value = "sajil.click"
    },
    {
    name  = "serviceAccount.create"
    value = "true"
    },
    {
    name  = "serviceAccount.name"
    value = "external-dns"
    },
    {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
    }
        ]
}


