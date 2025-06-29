# 🏗️ AWS Control Tower Setup Guide

Complete setup guide for AWS Control Tower multi-account environment with serverless application deployment.

## 📋 **Prerequisites**

- AWS Management Account with billing access
- Administrative permissions in AWS Organizations
- Domain for email addresses (for account creation)
- AWS CLI and CDK installed locally

## 🚀 **Phase 1: AWS Control Tower Setup**

### Step 1: Enable Control Tower
```bash
# Go to AWS Control Tower console
# Choose your home region (ap-southeast-1)
# Set up landing zone with:
# - Log Archive account
# - Audit account
# - Additional OU for workloads
```

### Step 2: Create Workload Accounts
Create 4 additional accounts in your organization:

| Account | Purpose | Recommended Email |
|---------|---------|-------------------|
| Development | Developer testing | dev@yourdomain.com |
| Staging | UAT & integration | staging@yourdomain.com |
| Shared | Cross-account resources | shared@yourdomain.com |
| Production | Live application | prod@yourdomain.com |

### Step 3: Account IDs Reference
```bash
# Update these with your actual account IDs:
DEV_ACCOUNT_ID=803133978889
STAGING_ACCOUNT_ID=521744733620
SHARED_ACCOUNT_ID=216665870694
PROD_ACCOUNT_ID=668427974646
MANAGEMENT_ACCOUNT_ID=926352914208
AUDIT_ACCOUNT_ID=<your-audit-account>
LOG_ARCHIVE_ACCOUNT_ID=<your-log-archive-account>
```

## 🔧 **Phase 2: Local Development Setup**

### Step 1: Install Dependencies
```bash
# Install Node.js 22+
npm install -g aws-cdk

# Verify installation
node --version
cdk --version
```

### Step 2: Configure AWS CLI
```bash
# Install AWS CLI v2
# Configure profiles for each account
aws configure --profile management
aws configure --profile dev
aws configure --profile staging
aws configure --profile shared
aws configure --profile prod
```

### Step 3: Bootstrap CDK
```bash
# Bootstrap each account (run from management account)
cdk bootstrap --qualifier cdk2024 --profile dev aws://DEV_ACCOUNT_ID/ap-southeast-1
cdk bootstrap --qualifier cdk2024 --profile staging aws://STAGING_ACCOUNT_ID/ap-southeast-1
cdk bootstrap --qualifier cdk2024 --profile shared aws://SHARED_ACCOUNT_ID/ap-southeast-1
cdk bootstrap --qualifier cdk2024 --profile prod aws://PROD_ACCOUNT_ID/ap-southeast-1
```

## 🔐 **Phase 3: GitHub Actions Setup**

### Step 1: Create OIDC Providers
For each account, create an OIDC identity provider:

```bash
# Development Account
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile dev

# Repeat for staging, shared, and prod accounts
```

### Step 2: Create IAM Roles
Create GitHub Actions roles in each account:

```bash
# Create role policy document
cat > github-actions-trust-policy.json << EOF
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USER/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Create roles (update ACCOUNT_ID for each)
aws iam create-role \
  --role-name GitHubActions-Dev-Role \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --profile dev

# Attach policies
aws iam attach-role-policy \
  --role-name GitHubActions-Dev-Role \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
  --profile dev
```

### Step 3: Update GitHub Actions Workflows
The workflows in `.github/workflows/` are already configured with your account IDs:
- Development: 803133978889
- Staging: 521744733620
- Production: 668427974646
- Shared: 216665870694

## 💰 **Phase 4: Cost Optimization**

### Understanding S3 Free Tier Alerts
**These alerts are NORMAL and expected** for Control Tower:

```
Account 926352914208 has exceeded 85% of S3 usage limit
- 2000 PUT/COPY/POST/LIST requests (free tier limit)
- Current usage: ~1700 requests
```

**Root Cause**: Control Tower creates organization-wide CloudTrail and Config, generating S3 requests across all 7 accounts.

### Cost Breakdown
```
Monthly Costs (All Active):
├── Management Account: $8-15 (Control Tower + CloudTrail)
├── Development: $2-5 (Lambda + API Gateway)
├── Staging: $3-6 (Larger Lambda allocation)
├── Shared: $3-6 (Cross-account resources)
├── Production: $4-8 (Optimized for performance)
├── Audit: $2-4 (Compliance logging)
└── Log Archive: $3-6 (Long-term storage)

Total: $35-70/month
With smart cleanup: $0.10/month (99% savings!)
```

### Smart Cost Management
```bash
# Destroy applications but keep infrastructure
./scripts/down.sh

# Restore when needed (2 minutes)
./scripts/up.sh

# Check status
npm run status
```

## 🧪 **Phase 5: Testing the Setup**

### Step 1: Deploy to Development
```bash
# Clone this repository
git clone <your-repo>
cd gctone
npm install

# Deploy to dev
cdk deploy ctone-dev --profile dev
```

### Step 2: Test CI/CD Pipeline
```bash
# Create a test feature branch
git checkout -b test/pipeline-validation

# Make a small change
echo "console.log('Pipeline test');" >> lib/lambda/main-handler.ts

# Commit and push
git add .
git commit -m "test: validate CI/CD pipeline"
git push origin test/pipeline-validation

# Create PR and observe:
# 1. CI validation runs automatically
# 2. Merge triggers dev deployment
# 3. Manual staging deployment available
# 4. Manual production deployment available
```

### Step 3: Verify All Endpoints
```bash
# Development
curl https://dev-api-url/
curl https://dev-api-url/health

# After staging deployment
curl https://staging-api-url/
curl https://staging-api-url/health

# After production deployment
curl https://prod-api-url/
curl https://prod-api-url/health
```

## 🔧 **Common Issues & Solutions**

### CDK Bootstrap Issues
```bash
# If bootstrap fails, check permissions
aws sts get-caller-identity --profile dev

# Re-bootstrap with force
cdk bootstrap --force --qualifier cdk2024 --profile dev
```

### GitHub Actions Authentication
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers --profile dev

# Check role trust policy
aws iam get-role --role-name GitHubActions-Dev-Role --profile dev
```

### Cost Alert Management
```bash
# Check current usage
aws s3api list-buckets --profile management

# Review CloudTrail configuration
aws cloudtrail describe-trails --profile management
```

## 📚 **Next Steps**

1. **Security Hardening**: Review IAM permissions and enable additional security features
2. **Monitoring Setup**: Configure CloudWatch dashboards and alerts  
3. **Backup Strategy**: Implement automated backup for critical data
4. **Disaster Recovery**: Plan and test recovery procedures
5. **Team Onboarding**: Create developer access and training materials

## 🎯 **Validation Checklist**

- [ ] 7 AWS accounts created and configured
- [ ] Control Tower landing zone active
- [ ] CDK bootstrapped in all workload accounts
- [ ] GitHub Actions OIDC providers created
- [ ] IAM roles configured for CI/CD
- [ ] Development deployment successful
- [ ] CI/CD pipeline tested end-to-end
- [ ] Cost optimization scripts working
- [ ] All endpoints responding correctly
- [ ] Monitoring and alerting configured

---

**🚀 You now have a production-ready AWS multi-account serverless application with automated CI/CD!**