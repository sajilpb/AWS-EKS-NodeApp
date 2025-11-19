# DevOps Kubernetes Deployment Pipeline with Argo CD, EKS & Canary Rollouts

This repository showcases a complete CI/CD pipeline for a microservices-based Node.js application using modern DevOps tooling including Argo CD, Argo Rollouts, AWS EKS, CodeBuild, ALB Ingress, and Route 53. The setup enables automated deployments to dev and production environments with canary rollout strategies.

## 🔧 Tech Stack

- **Application Stack**: Node.js + NGINX + Redis
- **Infrastructure**: Terraform + AWS EKS + ALB Ingress + Route 53 + ACM
- **CI/CD**: AWS CodeBuild + Argo CD + Argo Rollouts
- **Containerization**: Docker + Amazon ECR
- **DNS & SSL**: ExternalDNS + Let's Encrypt (or ACM) with SSL termination at ALB

## 🚀 Features

- Automated image builds and pushes with CodeBuild
- Environment-specific deployments:
  - **Dev**: Continuous deployment with updated image tag
  - **Prod**: Triggered via promotion (no rebuild), uses canary deployment with rollback
- Argo CD GitOps-based deployment management
- Argo Rollouts for automated and observable progressive delivery
- Single shared ALB with path-based or host-based routing
- ExternalDNS auto-manages Route53 entries
- HTTPS termination at ALB using ACM

## 🗂️ Repository Structure

```
.
├── modules/
│   ├── eks/               # EKS cluster provisioning
│   ├── vpc/               # Networking setup
│   ├── codebuild/         # Image build pipeline
│   ├── ecr/               # Container registry
│   ├── argocd/            # Argo CD installation
│   ├── alb/               # ALB Ingress Controller setup
│   ├── route53/           # ExternalDNS and domain setup
│   └── argo-rollouts/     # Canary controller and dashboard
├── helm/
│   └── nodeapp/           # Helm chart for the Node.js app
├── applications/
│   ├── Argoapplications-dev.yaml     # Dev namesapce  Values for Argo CD chart
│   └── Argoapplications-prod.yaml    # Prod namespace Values for Argo CD chart
├── main.tf
└── README.md
```

## ⚙️ Deployment Strategy

### Dev Environment
- Merge to `dev` triggers CodeBuild
- New Docker image is pushed to ECR
- Helm values file is auto-updated with the new tag (PR or commit)
- Argo CD syncs and deploys immediately to `dev` namespace

### Prod Environment
- Merge to `main` triggers a promotion (not a rebuild)
- The existing Dev tag is reused (immutable images)
- Canary rollout via Argo Rollouts (20%-40%-100%)
- Auto rollback if health checks fail

## 🛡️ Security

- All service accounts are IAM-bound using IRSA (IAM Roles for Service Accounts)
- SSL termination happens at ALB via ACM certificates
- Admin password for Argo CD is bcrypt-hashed

## 🌐 Domain and Routing

- `argocd.sajil.click` → Argo CD UI
- `prod.sajil.click` → Argo Rollouts dashboard
- `dev.sajil.click` → Node.js app (frontend)
- ALB ingress configured with unique hostnames for each service

## 🧪 Canary Deployment Observability
- Real-time traffic shifting via Argo Rollouts
- Manual pause windows with optional auto-promotion
- Integrated rollback on failed health checks

## 🛠️ Usage

```bash
# Initialize and apply infrastructure
terraform init
terraform apply

# Apply the Argo ingress and Argo application manifest file
kubectl apply -f applications/Argoapplications-dev.yaml
kubectl apply -f applications/Argoapplications-prod.yaml

# Verify Argo CD is up
kubectl get svc -n argocd

# Access UI
https://argocd.sajil.click
```

## ✅ Requirements

- AWS CLI & IAM credentials
- Terraform v1.5+
- kubectl v1.24+
- Helm v3
- Route 53 domain and ACM-issued SSL certs
- Docker + ECR access

## 📸 Screenshots

> _(Add UI snapshots for Argo CD, Argo Rollouts, etc., here if desired)_

## 🙌 Acknowledgments

- [Argo CD](https://argo-cd.readthedocs.io/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 📬 Contact

**Author**: Sajil PB  
**Domain**: [sajil.click](http://sajil.click)
