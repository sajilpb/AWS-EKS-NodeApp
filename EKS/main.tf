################################################################
#. Codebuild Module
################################################################
module "codebuild" {
  source                              = "./modules/codebuild"
  Codebuild-project-name              = var.Codebuild-project-name
  Codebuild-project-name-description  = var.Codebuild-project-name-description
  Source-repo                         = var.Source-repo
  source-buildspec-file               = var.source-buildspec-file
  source-branch                       = var.source-branch
}

################################################################
# VPC Module
################################################################
module "vpc" {
  source = "./modules/vpc"
}

################################################################
# EKS Module
################################################################
module "eks" {
  source               = "./modules/eks"
  subnet_ids           = module.vpc.private_subnets
  vpc_id               = module.vpc.vpc_id
  aws_eks_cluster_name = var.cluster_name
}

################################################################
# ECR Module
################################################################
module "ecr" {
  source              = "./modules/ecr"
  ecr_repository_name = var.ecr_repository_name
}

################################################################
# ALB Module
################################################################
module "alb" {
  source            = "./modules/alb"
  main-region       = var.main-region
  env_name          = var.env_name
  cluster_name      = var.cluster_name
  depends_on        = [module.eks]
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
}

################################################################
# Route53 Module
################################################################
module "route53" {
  source            = "./modules/route53"
  domain_name       = var.domain_name
  depends_on        = [module.eks]
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name      = var.cluster_name
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
}

################################################################
# Argo Module
################################################################
module "argocd" {
  source       = "./modules/argocd"
  cluster_name = var.cluster_name
  main-region  = var.main-region
  vpc_id       = module.vpc.vpc_id
  depends_on   = [module.eks,module.route53 ]
}
