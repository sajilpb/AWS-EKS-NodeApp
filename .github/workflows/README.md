# GitHub Actions Workflows Documentation

This document describes the GitHub Actions workflows configured for the AWS EKS Node App Terraform project.

## Workflows Overview

### 1. Terraform PR Checks (`terraform-pr-checks.yml`)

Runs automatically on every pull request and push to the `main` branch that modifies Terraform files.

#### Triggers
- Pull requests affecting `**.tf` or `**.tfvars` files
- Pushes to `main` branch affecting Terraform files

#### Checks Performed

**1. Terraform Format Check**
- Validates that all Terraform files follow the standard formatting conventions
- Command: `terraform fmt -check -recursive .`
- Fails if any files need reformatting

**2. Terraform Init**
- Initializes Terraform with `-backend=false` (doesn't require AWS credentials)
- Ensures all required providers and modules can be downloaded

**3. Terraform Validate**
- Validates the syntax and logic of all Terraform configurations
- Checks for missing variables, invalid references, etc.

**4. Terraform Plan**
- Generates a Terraform execution plan without applying changes
- Displays what infrastructure changes would occur
- Output is saved and displayed in the job summary

**5. tfsec Security Scan**
- Runs static security analysis on Terraform code
- Detects:
  - Insecure S3 bucket configurations
  - Missing encryption settings
  - Overly permissive IAM policies
  - Public database access
  - Other security misconfigurations
- Categorizes findings by severity (Critical, High, Medium, Low)
- **Fails the workflow if Critical issues are found**
- Results are uploaded to GitHub Code Scanning for inline code review

#### Output
- GitHub Step Summary with detailed results for each check
- PR comment with a summary table of all check results
- SARIF report uploaded to GitHub Code Scanning

---

### 2. Terraform Apply on Merge (`terraform-apply.yml`)

Runs automatically when changes are merged to the `main` branch.

#### Triggers
- Pushes to `main` branch affecting Terraform files

#### Steps

**1. Checkout Code**
- Gets the latest code from the main branch

**2. AWS Credentials Configuration**
- Configures AWS credentials using GitHub secrets
- Uses OIDC role assumption for secure credential-less authentication

**3. Terraform Init**
- Initializes Terraform with backend configuration
- Connects to the remote state backend (ensure your backend is configured)

**4. Terraform Validate**
- Final validation before applying changes

**5. Terraform Apply**
- Applies approved Terraform changes to AWS
- Uses `-auto-approve` flag to skip interactive approval
- Shows the final infrastructure state

---

## Setup Instructions

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

#### For Terraform Apply Workflow (Optional for PR checks)

```
AWS_ROLE_TO_ASSUME          # ARN of the IAM role to assume for AWS access
AWS_REGION                  # AWS region (e.g., us-east-1)
```

**Example IAM Role Trust Relationship for OIDC:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:sajilpb/AWS-EKS-NodeApp:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### 2. Configure Terraform Backend (Optional)

For the Apply workflow to work with remote state, update your `provider.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "eks-nodeapp/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. Local Development

Before pushing, you can run the same checks locally:

```bash
# Format check
terraform fmt -check -recursive .

# Validate
terraform init -backend=false
terraform validate

# Plan
terraform plan

# Security scan (if tfsec installed)
tfsec .
```

**Install tfsec locally:**
```bash
# macOS
brew install tfsec

# Linux
wget https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64
chmod +x tfsec
sudo mv tfsec /usr/local/bin/
```

---

## Workflow Behavior

### On Pull Request
1. ✅ All checks run (format, init, validate, plan, tfsec)
2. 📝 PR comment posted with summary table
3. 🔍 tfsec findings appear in Code Scanning tab
4. ⛔ Merge is blocked if critical issues are found
5. ✅ Merge is allowed only if all checks pass

### On Merge to Main
1. ✅ PR checks run again to ensure quality
2. 🚀 Terraform apply runs automatically
3. 📊 Infrastructure changes are applied to AWS
4. 📤 Plan output is displayed in job summary

---

## Customization

### Change Terraform Version
Edit the version in both workflow files:
```yaml
TERRAFORM_VERSION: 1.6.0  # Change this value
```

### Change tfsec Version
Edit the version in the PR checks workflow:
```yaml
TFSEC_VERSION: v1.28.1  # Change this value
```

### Adjust tfsec Severity Threshold
In `terraform-pr-checks.yml`, modify this section to fail on HIGH or MEDIUM severity:
```bash
if [ "$HIGH_COUNT" -gt 0 ]; then
  exit 1
fi
```

### Disable Specific tfsec Checks
```yaml
- name: Run tfsec Security Scan
  run: |
    tfsec . -f json --exclude aws-s3-enable-versioning,aws-ec2-no-public-ip
```

---

## Troubleshooting

### "terraform init failed: backend initialization required"
**Solution:** The Apply workflow needs AWS credentials configured. Set up AWS secrets and IAM role as described above.

### "Critical security issues found"
**Solution:** Review tfsec findings in the Code Scanning tab and fix the issues, or exclude specific checks if they're false positives.

### "Plan shows unexpected changes"
**Solution:** Ensure your Terraform variables are correctly set and backend state is properly configured.

### PR comments not appearing
**Solution:** Verify the GitHub token has `pull-requests: write` permission (already configured in workflows).

---

## Best Practices

1. **Review All tfsec Findings:** Even low-severity findings should be reviewed
2. **Test Locally:** Run checks locally before pushing to catch issues early
3. **Use Descriptive Commit Messages:** Include what infrastructure changes you're making
4. **Monitor Apply Failures:** Check workflow logs if apply fails unexpectedly
5. **Backup State:** Regularly backup your Terraform state file
6. **Lock State:** Use DynamoDB locks to prevent concurrent modifications

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EKS Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/)
