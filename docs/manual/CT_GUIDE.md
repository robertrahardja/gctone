# AWS Control Tower + CDK v2 Greenfield Setup Guide

A complete, step-by-step guide for setting up AWS Control Tower with CDK v2
from scratch. **This guide prioritizes automation and best practices** to
minimize manual work and reduce errors.

> **🌍 Universal Guide**: Works in any AWS region. Examples show Singapore
> (ap-southeast-1) but all commands work globally.

---

## 🚀 Setup Overview: Manual vs Automated

### **⏱️ Time Investment**

- **Total Time**: ~1.5 hours (was ~4 hours before consolidation)
- **Manual Work**: ~45 minutes (Control Tower setup only)
- **Automated Work**: ~10 minutes (single consolidated script)
- **Wait Time**: ~35 minutes (AWS provisioning, reduced with better detection)

### **🎯 Best Practice Approach**

1. **Phase 1**: Manual prerequisites & Control Tower setup (cannot be automated)
2. **Phase 2**: **Single automated command** for complete post-setup
3. **Phase 3**: Email confirmations & verification

---

## 📋 What's Manual vs Automated

### **❌ MANUAL (Cannot Be Automated - AWS Security Requirements)**

| Task | Why Manual | Time |
|------|------------|------|
| **Root Account MFA** | Security verification required | 5 min |
| **Control Tower Setup** | Legal acceptance & org decisions | 30 min |
| **Email Confirmations** | AWS security requirement | 5 min |
| **SSO Login Refresh** | Security tokens expire | 2 min |

### **✅ AUTOMATED (Zero Manual Work After Control Tower)**

| Task | Script | What It Does |
|------|---------|-------------|
| **Complete Environment** | `up.sh` | Complete setup: discovery, SSO, CDK bootstrap, validation, cost protection, deployment |
| **Smart Cost Management** | `down.sh` | 4 options: Smart savings, deep clean, nuclear, status check |

### **🎯 Ultra-Modern Approach: 2-Script Solution**

```bash
# After Control Tower setup, TWO commands handle everything:
./scripts/up.sh    # Complete environment setup (15 minutes)
./scripts/down.sh  # Smart cost management (2-15 minutes)
```

> **💡 Best Practice**: This guide uses **maximum automation** to eliminate
> human error and reduce setup time by 70%.

---

## 🏁 Complete Greenfield Setup Process

### **📋 The Complete Journey (Start to Finish)**

For a **brand new AWS organization**, here's exactly what you'll do:

#### **Phase 1: Prerequisites (15 minutes - Manual)**

1. ✅ Set up root account MFA
2. ✅ Create IAM admin user
3. ✅ Install tools (Node.js, AWS CLI, CDK)
4. ✅ Configure AWS SSO profile

#### **Phase 2: Control Tower Setup (30 minutes - Manual)**

1. ✅ Run Control Tower wizard in AWS Console
2. ✅ Configure core accounts (Audit, Log Archive)
3. ✅ Wait for AWS to provision everything

#### **Phase 3: Complete Automation (15 minutes - Automated)**

```bash
# Single command does everything:
./scripts/up.sh
```

#### **Phase 4: Email Confirmations (5 minutes - Manual)**

1. ✅ Check email inbox
2. ✅ Click "Confirm subscription" on all AWS SNS emails

### **🎯 What You Get**

- **7 AWS accounts** (Management, Audit, Log Archive, Dev, Staging, Shared, Prod)
- **Working SSO profiles** for all environments (tar-dev, tar-staging, etc.)
- **CDK bootstrap complete** in all accounts
- **Ready for immediate deployment**
- **Enterprise-grade governance** and security baseline
- **Production-ready infrastructure** you can build upon
- **Smart cost management** with instant destroy/redeploy capabilities

### **💰 Total Cost & Smart Savings**

- **Setup cost**: $0 (all automation is free)
- **Active development**: ~$35-70 USD/month
- **Cost savings mode**: ~$0.10 USD/month (99% reduction)
- **Redeploy time**: 2 minutes (instant resume)
- **ROI**: Saves 50+ hours vs manual AWS setup

> **🚀 Ready to start?** Check [GREENFIELD_MANUAL_SETUP.md](./GREENFIELD_MANUAL_SETUP.md)
> for complete manual prerequisites, then run `./scripts/up.sh`.

---

## 💰 Cost Analysis

### Monthly Cost Estimates

#### **Core Control Tower Infrastructure** (Required)

- **AWS Organizations**: Free
- **Control Tower Service**: Free
- **CloudTrail Organization Trail**: ~$2-5/month (depends on API calls)
- **AWS Config**: ~$10-20/month (all accounts, basic rules)
- **S3 Storage (Logs)**: ~$5-15/month (CloudTrail + Config data)
- **CloudWatch Logs**: ~$5-10/month (retention costs)

**Infrastructure Subtotal: $22-50/month**

#### **Hello World Applications** (Per Environment)

- **Lambda Functions**: ~$0.20/month per environment (minimal usage)
- **API Gateway HTTP API**: ~$1/month per environment (1000 requests/month)
- **CloudWatch Log Groups**: ~$0.50/month per environment

**Per Environment: ~$1.70/month**
**All 4 Environments: ~$7/month**

#### **Cost Management Services** (Optional but Recommended)

- **AWS Budgets**: $0.20/month per budget (5 budgets = $1/month)
- **CloudWatch Billing Alarms**: ~$0.30/month (3 alarms)
- **SNS Notifications**: <$0.10/month (email only)

**Management Subtotal: ~$1.50/month**

### **Total Monthly Cost**

| Region | Monthly Cost | Annual Cost |
|--------|--------------|-------------|
| **US East 1 (Virginia)** | $30-60 | $360-720 |
| **🇸🇬 Singapore (ap-southeast-1)** | $35-70 (+15%) | $420-840 |

### **Cost Breakdown by Account**

| Account | Services | Monthly Cost |
|---------|----------|--------------|
| **Management** | Organizations, Control Tower, Billing | $15-25 |
| **Log Archive** | S3 storage, data transfer | $10-20 |
| **Audit** | Config aggregation, minimal compute | $5-10 |
| **Development** | Lambda (128MB), API Gateway, logs | $2-5 |
| **Staging** | Lambda (256MB), API Gateway, logs | $3-6 |
| **Shared Services** | Lambda (256MB), API Gateway, logs | $3-6 |
| **Production** | Lambda (512MB), API Gateway, logs | $4-8 |

### **First Month with AWS Free Tier**

| Service | Free Tier Benefit | Savings |
|---------|-------------------|---------|
| **Lambda** | 1M requests/month free | ~$5-10 |
| **API Gateway** | 1M requests/month free | ~$3-5 |
| **CloudWatch** | 10 GB logs free | ~$3-5 |
| **S3** | 5 GB storage free | ~$1-2 |

**First Month Cost (with free tier): $20-40**
**Steady State (after 12 months): $30-70**

### **Built-in Cost Optimization Features**

- ✅ **HTTP API vs REST API**: 70% cheaper
- ✅ **ARM64 Lambda**: 20% cheaper than x86
- ✅ **Environment-specific sizing**: Dev uses minimal resources
- ✅ **Short log retention**: 1 week dev, 1 month prod
- ✅ **Automated budget alerts**: 50%, 80%, 100% thresholds

### **Recommended Budget Allocation**

```
Management Account:    $10 SGD/month
Audit Account:         $5 SGD/month
Log Archive:           $10 SGD/month
Development:           $10 SGD/month
Staging:               $10 SGD/month
Shared Services:       $10 SGD/month
Production:            $10 SGD/month
Total Budget:          $65 SGD/month (with buffer)
```

### **ROI Justification**

**What You Get for $35-70/month:**

- ✅ Enterprise-grade governance (normally $1000s/month consultant fees)
- ✅ Multi-account security baseline
- ✅ Automated compliance monitoring
- ✅ Cost management and alerts
- ✅ CI/CD ready infrastructure
- ✅ Production-ready foundation

**Compared to Alternatives:**
- Manual AWS setup: 40+ hours @ $100/hr = $4000
- Terraform Enterprise: $20-50/user/month
- AWS Control Tower: Built-in governance at infrastructure cost only

> **💡 Bottom Line**: Complete production-ready AWS foundation for the cost of a few coffee subscriptions per month!

---

## ✅ Phase 1: Prerequisites and Environment Setup

### 1.1 System Requirements Check

- [ ] **Check Node.js version** (Need 20+ minimum, 22+ recommended)
  ```bash
  node --version
  # Expected: v22.x.x (recommended) or v20.x.x (minimum)
  ```

- [ ] **Check npm version**
  ```bash
  npm --version
  # Expected: 10.x.x or higher
  ```

- [ ] **Check AWS CLI version** (need v2.15+)
  ```bash
  aws --version
  # Expected: aws-cli/2.15.x or higher
  ```

- [ ] **Check Git version**
  ```bash
  git --version
  # Expected: git version 2.40.x or higher
  ```

### 1.2 Install Latest Tools

- [ ] **Install Node.js 22** (choose one method)
  ```bash
  # macOS with Homebrew
  brew install node@22
  brew link node@22

  # OR use nvm
  nvm install 22
  nvm use 22
  nvm alias default 22

  # OR Ubuntu/Debian
  curl -fsSL <https://deb.nodesource.com/setup_22.x> | sudo -E bash -
  sudo apt-get install -y nodejs
  ```

- [ ] **Install/Update AWS CLI v2**
  ```bash
  # macOS
  brew install awscli

  # OR Linux
  curl "<https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"> -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install --update
  ```

### 1.3 Configure AWS CLI

**⚠️ IMPORTANT**: Do not use root account credentials for CLI access. Follow security best practices:

#### Create IAM User (Recommended)

- [ ] **Log into AWS Console with root account**
- [ ] **Go to IAM → Users → Create User**
- [ ] **User Creation Form:**
  - User name: `control-tower-admin`
  - Choose: "I want to create an IAM user"
- [ ] **Set permissions:**
  - Choose: "Attach policies directly"
  - Search and select: "AdministratorAccess"
  - ✅ Check the box next to AdministratorAccess policy
- [ ] **Review and create user**
  - Tags (optional): Key="Purpose", Value="ControlTower"
  - Click "Create user"
- [ ] **Create access keys:**
  - Click on the newly created user → Security credentials tab
  - Scroll to "Access keys" section → "Create access key"
  - Use case selection: ✅ Select "Command Line Interface (CLI)"
  - ✅ Check: "I understand the above recommendation and want to proceed to create an access key"
  - Click "Next"
  - Description: "Control Tower CDK Operations"
  - Click "Create access key"
  - ⚠️ **CRITICAL**: Download .csv file or copy both keys immediately
- [ ] **Enable MFA on IAM user:**
  - Security credentials tab → Multi-factor authentication (MFA)
  - "Assign MFA device" → Choose authenticator app
  - Follow setup instructions
- [ ] **Configure AWS CLI with IAM user credentials**
  ```bash
  aws configure
  # AWS Access Key ID: [IAM user access key from above]
  # AWS Secret Access Key: [IAM user secret key from above]
  # Default region name: us-east-1  # or ap-southeast-1 for Singapore
  # Default output format: json
  ```
- [ ] **Verify configuration**
  ```bash
  aws sts get-caller-identity
  # Should show: "arn:aws:iam::account:user/control-tower-admin"
  # NOT: "arn:aws:iam::account:root"
  ```

#### option b: using aws profiles (advanced)

```bash
# create named profile for better organization
aws configure --profile control-tower-admin
# use iam user credentials (not root)

# set default profile
export aws_profile=control-tower-admin

# or use profile with each command
aws --profile control-tower-admin sts get-caller-identity
```

#### security best practices

```bash
# ✅ do:
# - create iam user with administratoraccess policy
# - choose "i want to create an iam user" (not identity center for this use case)
# - select "command line interface (cli)" as access key use case
# - acknowledge aws recommendations and proceed with access key creation
# - enable mfa on root account and iam user
# - use iam user credentials for cli operations
# - download/save access keys immediately (you can't see secret key again)
# - store access keys securely (password manager, encrypted storage)
# - delete root access keys after iam user setup
# - rotate access keys regularly (every 90 days)

# ❌ don't:
# - use root account access keys for cli operations
# - share credentials or commit them to version control
# - skip mfa setup on either account
# - use identity center for programmatic/cdk access (use iam user instead)
# - use cloudshell for long-running cdk operations (session timeouts)
# - lose your access keys (you'll need to create new ones)
# - ignore aws security recommendations (but understand when they don't apply)

# 💡 why iam user instead of identity center for this guide?
# - control tower and cdk need programmatic access (access keys)
# - identity center is great for human console access
# - iam users are recommended for automation and cli operations
# - this setup gives you the access needed for control tower deployment
#
# 💡 why access keys instead of aws alternatives?
# - cloudshell: limited session time, not suitable for long cdk deployments
# - identity center cli: adds complexity for single-account control tower setup
# - access keys: provide persistent access needed for control tower automation
# - this is a legitimate use case for access keys (cli automation)
#
# 🔐 access key security:
# - store in secure location (password manager, encrypted file)
# - never commit to version control
# - rotate regularly (every 90 days recommended)
# - delete if compromised
# - monitor usage in cloudtrail
```

### 1.4 Install Latest CDK v2

- [ ] **Install CDK v2 globally**
  ```bash
  npm install -g aws-cdk@latest
  ```
- [ ] **Verify installation** (should be 2.201.0+)
  ```bash
  cdk --version
  # Expected: 2.201.x or higher
  ```

---

## ✅ Phase 2: Email Accounts Setup

### 2.1 Prepare Email Accounts

- [ ] **Prepare 7 email addresses** (you can use Gmail aliases):
  - [ ] **Management account (root)**: `your-email@gmail.com`
  - [ ] **Audit account**: `your-email-audit@gmail.com`
  - [ ] **Log archive account**: `your-email-logs@gmail.com`
  - [ ] **Production workload**: `your-email+prod@gmail.com`
  - [ ] **Staging workload**: `your-email+staging@gmail.com`
  - [ ] **Development workload**: `your-email+dev@gmail.com`
  - [ ] **Shared services**: `your-email+shared@gmail.com`

> **🇸🇬 Singapore note**: Same email structure works for Singapore - the region doesn't affect email requirements.

### 2.2 Initial Security Setup

- [ ] **Enable MFA on root account**
  - Go to: AWS Console → Account menu (top right) → Security credentials
  - Multi-factor authentication (MFA) → Assign MFA device
  - Use authenticator app (Google Authenticator, Authy, etc.)

- [ ] **Create IAM user for daily operations** (if not done in Phase 1)
  - Go to: IAM → Users → Create user
  - User name: `control-tower-admin`
  - Permissions: Attach AdministratorAccess policy directly
  - Create access keys for CLI access

- [ ] **Enable MFA on IAM user**
  - IAM → Users → control-tower-admin → Security credentials
  - Assign MFA device

- [ ] **Test IAM user access**
  ```bash
  aws sts get-caller-identity
  # Should show IAM user ARN, not root
  ```

- [ ] **Delete root access keys** (if any exist)
  - AWS Console → Account menu → Security credentials
  - Delete any existing access keys

- [ ] **Verify security setup is complete**
  ```bash
  echo "✅ Security setup complete - ready for Control Tower"
  ```

---

## ✅ Phase 3: CDK Project Structure

### 3.1 Initialize Project

- [ ] **Create project directory**
  ```bash
  mkdir simple-control-tower-cdk
  cd simple-control-tower-cdk
  ```

- [ ] **Initialize TypeScript CDK project**
  ```bash
  cdk init app --language typescript
  ```

### 3.2 Install Dependencies

- [ ] **Install core CDK v2 dependencies**
  ```bash
  npm install aws-cdk-lib@latest constructs@latest
  ```

- [ ] **Install development dependencies**
  ```bash
  npm install --save-dev @types/node@latest @types/aws-lambda@latest
  ```

- [ ] **Verify versions**
  ```bash
  npm list aws-cdk-lib
  ```

### 3.3 Create Directory Structure

- [ ] **Create directory structure**
  ```bash
  mkdir -p lib/{stacks,constructs,config,lambda}
  mkdir -p scripts
  ```

- [ ] **Create required files**
  ```bash
  touch lib/config/accounts.ts
  touch lib/constructs/hello-world-app.ts
  touch lib/stacks/application-stack.ts
  touch lib/lambda/main-handler.ts
  touch lib/lambda/health-handler.ts
  touch scripts/get-account-ids.sh
  touch scripts/bootstrap-accounts.sh
  touch scripts/deploy-applications.sh
  touch scripts/validate-deployment.sh
  touch scripts/sync-account-emails.sh
  touch scripts/create-per-account-alerts.sh
  ```

---

## ✅ Phase 4: Configuration Files

### 4.1 Account Configuration

- [ ] **Create `lib/config/accounts.ts`** with the following content (emails will be auto-updated later):

```typescript
export interface accountconfig {
  name: string;
  email: string;
  environment: "prod" | "staging" | "dev" | "shared";
  helloworldmessage: string;
  memorysize: number;
  timeout: number;
}

export const accounts: Record<string, accountconfig> = {
  dev: {
    name: "development",
    email: "your-email+dev@gmail.com", // replace with your email
    environment: "dev",
    helloworldmessage: "hello from development! 💻",
    // 🇸🇬 singapore version: "hello from singapore development! 🇸🇬💻",
    memorysize: 128, // minimal for cost optimization
    timeout: 10,
  },
  staging: {
    name: "staging",
    email: "your-email+staging@gmail.com", // replace with your email
    environment: "staging",
    helloworldmessage: "hello from staging! 🧪",
    // 🇸🇬 singapore version: "hello from singapore staging! 🇸🇬🧪",
    memorysize: 256,
    timeout: 15,
  },
  shared: {
    name: "shared-services",
    email: "your-email+shared@gmail.com", // replace with your email
    environment: "shared",
    helloworldmessage: "hello from shared services! 🔧",
    // 🇸🇬 singapore version: "hello from singapore shared services! 🇸🇬🔧",
    memorysize: 256,
    timeout: 15,
  },
  prod: {
    name: "production",
    email: "your-email+prod@gmail.com", // replace with your email
    environment: "prod",
    helloworldmessage: "hello from production! 🚀",
    // 🇸🇬 singapore version: "hello from singapore production! 🇸🇬🚀",
    memorysize: 512,
    timeout: 30,
  },
};

export const core_accounts = {
  management: "your-email@gmail.com", // replace with your email
  audit: "your-email-audit@gmail.com", // replace with your email
  logarchive: "your-email-logs@gmail.com", // replace with your email
};
```

> **💡 Pro Tip**: You can automatically sync emails from your AWS organization using the provided script:
> ```bash
> ./scripts/sync-account-emails.sh
> ```
> This script fetches the actual emails from your AWS accounts and **automatically updates** the config file. It creates a backup first for safety.

---

## ✅ Phase 5: Manual Control Tower Setup

### 5.1 Access Control Tower Console

- [ ] **Log into AWS Console with ROOT account credentials**
- [ ] **Navigate to Control Tower console**
  - Go to: <https://console.aws.amazon.com/controltower/>
  - 🇸🇬 Singapore: <https://ap-southeast-1.console.aws.amazon.com/controltower/>
- [ ] **Verify you are in the correct region** (top-right corner)
  - US East 1: `us-east-1`
  - 🇸🇬 Singapore: `ap-southeast-1`

### 5.2 Landing Zone Configuration

- [ ] **Click "Set up landing zone" button**
- [ ] **Select Home Region:**
  - US East 1: `us-east-1`
  - 🇸🇬 Singapore: `ap-southeast-1` (**cannot be changed later**)
- [ ] **Configure Organizational Units (OUs):**
  - Security OU: `Security` (default)
  - Sandbox OU: `Sandbox` (default)

### 5.3 Account Configuration

- [ ] **Configure core accounts using your prepared emails:**
  - [ ] **Management Account:** Already your current account
  - [ ] **Audit Account:**
    - Email: `your-email-audit@gmail.com`
    - Account Name: `Audit`
    - OU: Security OU
  - [ ] **Log Archive Account:**
    - Email: `your-email-logs@gmail.com`
    - Account Name: `Log Archive`
    - OU: Security OU

### 5.4 Compliance and Governance

> **⚠️ Note**: These configurations are part of the Control Tower setup wizard and **cannot be automated**. They establish the foundational security baseline for your organization.

#### 5.4.1 Guardrails Selection

- [ ] **Navigate to Guardrails section** in Control Tower setup wizard
- [ ] **Review Preventive Guardrails** (automatically applied policies that prevent actions):
  - [ ] **Disallow changes to CloudTrail** - Prevents modification of organization trail
  - [ ] **Disallow deletion of log streams** - Protects CloudWatch logs
  - [ ] **Disallow configuration changes to CloudWatch** - Prevents log tampering
  - [ ] **Check "Enable all strongly recommended guardrails"** checkbox
  - [ ] **Check "Enable all elective guardrails"** checkbox (optional but recommended)
- [ ] **Review Detective Guardrails** (monitoring and alerting on non-compliant actions):
  - [ ] **Detect whether MFA is enabled for root user** - Security monitoring
  - [ ] **Detect whether public access to S3 buckets is allowed** - Data protection
  - [ ] **Detect whether encryption is enabled for EBS volumes** - Data security
  - [ ] **Check "Enable all strongly recommended detective guardrails"** checkbox
  - [ ] **Check "Enable all elective detective guardrails"** checkbox (optional)

#### 5.4.2 CloudTrail Configuration

- [ ] **Navigate to CloudTrail section** in Control Tower setup wizard
- [ ] **Organization CloudTrail Settings:**
  - [ ] **Check "Enable organization-wide CloudTrail"** checkbox
  - [ ] **Trail name:** Accept default `aws-controltower-BaselineCloudTrail`
  - [ ] **S3 bucket location:** Will be auto-created in Log Archive account
  - [ ] **S3 bucket name:** Accept default `aws-controltower-logs-ACCOUNT-REGION`
- [ ] **Log Configuration:**
  - [ ] **Log retention:** Select `90 days` (default, good balance of cost vs compliance)
  - [ ] **Include global services:** ✅ Enabled (captures IAM, Route 53, etc.)
  - [ ] **Include management events:** ✅ Enabled (captures API calls)
  - [ ] **Include data events:** ❌ Disabled (optional, increases costs significantly)
- [ ] **Encryption Settings:**
  - [ ] **Server-side encryption:** ✅ Enabled (uses AWS managed keys)
  - [ ] **Log file validation:** ✅ Enabled (ensures log integrity)

#### 5.4.3 AWS Config Configuration

- [ ] **Navigate to AWS Config section** in Control Tower setup wizard
- [ ] **Configuration Recording:**
  - [ ] **Check "Enable AWS Config in all accounts"** checkbox
  - [ ] **Recording scope:** Select `Record all resources` (comprehensive compliance)
  - [ ] **Include global resources:** ✅ Enabled (IAM resources, etc.)
- [ ] **Delivery Settings:**
  - [ ] **S3 bucket:** Will use same bucket as CloudTrail in Log Archive account
  - [ ] **S3 key prefix:** Accept default `AWSConfig`
  - [ ] **SNS topic:** Accept default (notifications for config changes)
- [ ] **Config Rules (Guardrails):**
  - [ ] **Automatic rules:** Will be deployed based on selected guardrails
  - [ ] **Custom rules:** None needed for basic setup
  - [ ] **Remediation:** Accept default settings (manual remediation)

### 5.5 Cost and Billing Setup

#### 5.5.1 Enable Cost and Usage Reports

- [ ] **Navigate to Cost Management section** in Control Tower setup wizard
- [ ] **Cost and Usage Reports (CUR):**
  - [ ] **Check "Enable Cost and Usage Reports"** checkbox
  - [ ] **Report name:** Accept default `aws-controltower-cur`
  - [ ] **S3 bucket:** Will be auto-created in management account
  - [ ] **Report format:** Select `Parquet` (efficient for large datasets)
  - [ ] **Compression:** Select `GZIP`
  - [ ] **Time granularity:** Select `Daily` (detailed cost tracking)
  - [ ] **Report versioning:** Select `Overwrite existing report`
- [ ] **Additional Data:**
  - [ ] **Include resource IDs:** ✅ Enabled (detailed resource tracking)
  - [ ] **Include split cost allocation data:** ✅ Enabled (reservation details)

#### 5.5.2 Set up Billing Alerts

- [ ] **After Control Tower setup, navigate to AWS Billing & Cost Management console**
- [ ] **Go to Billing preferences:**
  - [ ] **Click "Billing preferences" in left navigation**
  - [ ] **Check "Receive Billing Alerts"** checkbox
  - [ ] **Save preferences**
- [ ] **Set up CloudWatch billing alarms:**

**Option A: Automated (Recommended)**
- [ ] **Run the automated billing alert script:**
  ```bash
  ./scripts/fix-missing-controltower-config.sh
  ```
  This script automatically creates:
  - Organization-wide alert with $50 SGD threshold
  - SNS topic for notifications
  - Email subscriptions for cost overruns

**Option B: Manual Setup**
- [ ] **Go to CloudWatch console → Alarms → Billing**
- [ ] **Click "Create alarm"**
- [ ] **Create Organization-wide Alert:**
  - [ ] **Metric:** Select `EstimatedCharges`
  - [ ] **Currency:** Select `SGD` (Singapore Dollars)
  - [ ] **Statistic:** `Maximum`
  - [ ] **Period:** `6 hours`
  - [ ] **Threshold:** `Static` > `Greater than` > `50`
  - [ ] **Alarm name:** `Organization-Monthly-Spend-Alert-$50-SGD`
  - [ ] **Create Per-Account Alerts** (automated):
    ```bash
    ./scripts/create-per-account-alerts.sh
    ```
    This script automatically creates $10 SGD billing alerts for:
    - Development, Staging, Shared Services, Production, Management accounts
    - Separate SNS topics for organized notifications
    - Email subscriptions for all cost overruns
- [ ] **Configure notification actions:**
  - [ ] **SNS topic:** Create new topic `billing-alerts`
  - [ ] **Email subscriptions:** Add your email addresses
  - [ ] **Confirm email subscriptions** when prompted

#### 5.5.3 Create Budgets

**Option A: Automated (Recommended)**
- [ ] **Run the automated budget creation script:**
  ```bash
  ./scripts/create-budgets.sh
  ```
  This script automatically creates $10 SGD budgets for all accounts with 50%, 80%, 100% alerts.

**Option B: Manual Setup**
- [ ] **Navigate to AWS Budgets console**
- [ ] **Click "Create budget"**
- [ ] **Create Organization Budget:**
  - [ ] **Budget type:** Select `Cost budget`
  - [ ] **Budget name:** `Organization-Monthly-Budget`
  - [ ] **Period:** `Monthly`
  - [ ] **Budget amount:** Enter `$50 SGD` (adjust based on expected usage)
  - [ ] **Budget scope:** Select `All AWS services`
  - [ ] **Filters:** Add `Account` filter and select all accounts
- [ ] **Configure budget alerts:**
  - [ ] **Alert 1:** `50%` of budgeted amount
    - [ ] **Threshold:** `50` percent of budget
    - [ ] **Email recipients:** Your primary email
    - [ ] **Alert name:** `50% Budget Alert`
  - [ ] **Alert 2:** `80%` of budgeted amount
    - [ ] **Threshold:** `80` percent of budget
    - [ ] **Email recipients:** Your primary email + team lead
    - [ ] **Alert name:** `80% Budget Alert - Action Required`
  - [ ] **Alert 3:** `100%` of budgeted amount
    - [ ] **Threshold:** `100` percent of budget
    - [ ] **Email recipients:** All stakeholders
    - [ ] **Alert name:** `Budget Exceeded - Immediate Action Required`
- [ ] **Create Per-Account Budgets** (repeat for each workload account):
  - [ ] **Development Account Budget:**
    - [ ] **Budget name:** `Development-Monthly-Budget`
    - [ ] **Amount:** `$10 SGD`
    - [ ] **Scope:** Filter by Development account only
    - [ ] **Alerts:** 50%, 80%, 100% thresholds
  - [ ] **Staging Account Budget:**
    - [ ] **Budget name:** `Staging-Monthly-Budget`
    - [ ] **Amount:** `$10 SGD`
    - [ ] **Scope:** Filter by Staging account only
    - [ ] **Alerts:** 50%, 80%, 100% thresholds
  - [ ] **Shared Services Budget:**
    - [ ] **Budget name:** `Shared-Services-Monthly-Budget`
    - [ ] **Amount:** `$10 SGD`
    - [ ] **Scope:** Filter by Shared Services account only
    - [ ] **Alerts:** 50%, 80%, 100% thresholds
  - [ ] **Production Account Budget:**
    - [ ] **Budget name:** `Production-Monthly-Budget`
    - [ ] **Amount:** `$10 SGD`
    - [ ] **Scope:** Filter by Production account only
    - [ ] **Alerts:** 50%, 80%, 100% thresholds
  - [ ] **Management Account Budget:**
    - [ ] **Budget name:** `Management-Monthly-Budget`
    - [ ] **Amount:** `$10 SGD`
    - [ ] **Scope:** Filter by Management account only
    - [ ] **Alerts:** 50%, 80%, 100% thresholds

#### 5.5.4 Additional Cost Optimization Settings

- [ ] **Enable Cost Allocation Tags:**
  - [ ] **Go to Billing & Cost Management → Cost allocation tags**
  - [ ] **Activate AWS-generated tags:**
    - [ ] `aws:createdBy`
    - [ ] `aws:cloudformation:stack-name`
    - [ ] `aws:cloudformation:logical-id`
  - [ ] **Create user-defined tags for activation:**
    - [ ] `Environment` (will be applied by CDK)
    - [ ] `Project` (will be applied by CDK)
    - [ ] `ManagedBy` (will be applied by CDK)
- [ ] **Set up Cost Explorer:**
  - [ ] **Go to Cost Explorer → Enable Cost Explorer**
  - [ ] **Wait 24 hours for data population**
  - [ ] **Create custom reports for:**
    - [ ] Daily costs by account
    - [ ] Monthly costs by service
    - [ ] Reserved instance recommendations
- [ ] **Configure AWS Trusted Advisor** (if Business/Enterprise support):
  - [ ] **Review cost optimization recommendations**
  - [ ] **Set up automated notifications for new recommendations**

### 5.6 Launch Setup

- [ ] **Review all configurations carefully**
- [ ] **Review estimated costs**
- [ ] **Click "Set up landing zone"**
- [ ] **Monitor setup progress** (30-70 minutes expected)
  - Check email confirmations for new accounts
  - Monitor the setup dashboard

### 5.7 Post-Setup Verification

- [ ] **Verify Control Tower status shows "Setup Succeeded"**
- [ ] **Check AWS Organizations console**
  - Confirm all 3 core accounts are listed
  - Verify account IDs and email addresses
- [ ] **Test account access**
  - Switch roles to Audit and Log Archive accounts
  - Verify OrganizationAccountAccessRole works
- [ ] **Verify guardrails status shows "Compliant"**
- [ ] **Check CloudTrail in Log Archive account**
  - Verify organization trail is active
  - Check S3 bucket for log delivery

### 5.8 Post-Setup Automation Options

After Control Tower setup completes, you have two options:

### 5.9 Fixing Missing Control Tower Configuration

> **⚠️ Did you skip some configuration during Control Tower setup?** Don't worry! Most people go through Control Tower with default settings. This section helps you add the missing **HIGH PRIORITY** features safely.

#### 5.9.1 Assessment: What Do You Currently Have?

- [ ] **Run the configuration assessment script:**
  ```bash
  ./scripts/fix-missing-controltower-config.sh
  ```
  This script will:
  - ✅ Check your current Control Tower status
  - ✅ Identify missing HIGH PRIORITY features
  - ✅ Show you exactly what needs to be added
  - ✅ Safely add missing cost controls

#### 5.9.2 High Priority Features (MUST HAVE - Prevent Cost Disasters)

If your assessment shows these are missing, **add them immediately**:

- [ ] **🚨 Billing Alerts** - Prevent cost surprises
  - Organization-wide spending alerts
  - Email notifications when thresholds exceeded
  - **Cost Impact**: Without this, you could get $1000s bills with no warning

- [ ] **💰 Budgets** - Control spending
  - Per-account spending limits with alerts
  - 50%, 80%, 100% alert thresholds
  - **Cost Impact**: Helps prevent runaway costs from misconfigured resources

- [ ] **🏷️ Cost Allocation Tags** - Track expenses
  - Environment-based cost tracking (dev/staging/prod)
  - Project-based expense attribution
  - **Cost Impact**: Essential for understanding where money is going

#### 5.9.3 Medium Priority Features (Good to Have)

- [ ] **Additional Guardrails** - Enhanced security controls
- [ ] **Cost and Usage Reports** - Detailed cost analysis
- [ ] **Advanced CloudTrail** - Data event logging (expensive)

#### 5.9.4 Low Priority Features (Nice to Have)

- [ ] **Custom Config Rules** - Specific compliance requirements
- [ ] **Advanced Monitoring** - Custom CloudWatch dashboards
- [ ] **Reserved Instance Planning** - For predictable workloads

#### 5.9.5 Quick Recovery Commands

If you need to add missing features quickly:

```bash
# 1. CRITICAL: Add cost controls (run immediately if missing)
./scripts/fix-missing-controltower-config.sh

# 2. Create per-account billing alerts ($10 SGD each)
./scripts/create-per-account-alerts.sh

# 3. Create detailed budgets (SGD currency)
./scripts/create-budgets.sh

# 4. Add comprehensive post-setup features
./scripts/setup-post-controltower.sh

# 4. Set up SSO (if not configured)
./scripts/setup-sso.sh
```

#### 5.9.6 Cost Impact of Missing Features

| Missing Feature | Potential Cost Impact | Risk Level |
|----------------|----------------------|------------|
| **No Billing Alerts** | Unlimited surprise bills | 🚨 CRITICAL |
| **No Budgets** | Runaway resource costs | 🚨 CRITICAL |
| **No Cost Tags** | Can't identify waste | 🔶 HIGH |
| **No Advanced Guardrails** | Security compliance issues | 🔶 MEDIUM |
| **No Cost Reports** | Limited cost optimization | 🟡 LOW |

> **💰 Real Example**: Without billing alerts, a misconfigured Lambda function could cost $500/day. With alerts, you'd know within hours and fix it quickly.

After Control Tower setup completes, you have three options:

#### Option A: Complete Automated Setup (🎯 **Recommended for Greenfield**)

- [ ] **ONE command does everything:**
  ```bash
  ./scripts/setup-complete-environment.sh
  ```
  This single script will automatically:
  - ✅ Discover all Control Tower account IDs
  - ✅ Set up SSO user assignments
  - ✅ Create SSO profiles (tar-dev, tar-staging, etc.)
  - ✅ Wait for SSO access to become ready
  - ✅ Bootstrap CDK in all accounts
  - ✅ Validate the complete setup

  **⏱️ Time**: 10-15 minutes total (mostly waiting for AWS provisioning)

  **✅ Perfect for**: New projects, greenfield setups, first-time users

#### Option B: Individual Automated Steps

If you prefer to run steps individually or troubleshoot issues:

- [ ] **Setup SSO only:**
  ```bash
  ./scripts/setup-sso-simple.sh your@email.com
  ```

- [ ] **Bootstrap CDK only** (after SSO is working):
  ```bash
  ./scripts/bootstrap-accounts.sh
  ```

- [ ] **Validate everything:**
  ```bash
  ./scripts/validate-complete-setup.sh
  ```

#### Option C: Manual Post-Setup (Legacy)

If you prefer manual setup or the scripts don't work in your environment:

- [ ] **Create Non-Production and Production OUs:**
  - AWS Organizations console → Organizational units
  - Create OU: `Non-Production` (parent: Root)
  - Create OU: `Production` (parent: Root)

- [ ] **Use Account Factory to create workload accounts:**
  - Control Tower console → Account Factory → "Create account"
  - [ ] **Development Account:**
    - Email: `your-email+dev@gmail.com`
    - Name: `Development`
    - OU: `Non-Production`
  - [ ] **Staging Account:**
    - Email: `your-email+staging@gmail.com`
    - Name: `Staging`
    - OU: `Non-Production`
  - [ ] **Shared Services Account:**
    - Email: `your-email+shared@gmail.com`
    - Name: `Shared Services`
    - OU: `Non-Production`
  - [ ] **Production Account:**
    - Email: `your-email+prod@gmail.com`
    - Name: `Production`
    - OU: `Production`

- [ ] **Configure IAM Identity Center (SSO):**

#### Option 1: Automated User Management (Recommended for Future Projects)

For **new projects**, automate the entire user creation and permission assignment process:

- [ ] **Use the UserManagement CDK construct** in your main stack:
  ```typescript
  import { UserManagement } from './lib/constructs/user-management';

  // Add to your main stack
  new UserManagement(this, 'UserManagement', {
    identityStoreId: 'd-xxxxxxxxxx', // From IAM Identity Center
    instanceArn: 'arn:aws:sso:::instance/ssoins-xxxxxxxxx',
    baseEmail: 'your-email@domain.com', // Creates +dev, +staging, etc.
    accounts: {
      dev: process.env.DEV_ACCOUNT_ID!,
      staging: process.env.STAGING_ACCOUNT_ID!,
      shared: process.env.SHARED_ACCOUNT_ID!,
      prod: process.env.PROD_ACCOUNT_ID!
    },
    organizationId: 'o-xxxxxxxxxx' // For cross-account access
  });
  ```

- [ ] **Run automated SSO profile setup:**
  ```bash
  ./scripts/setup-automated-sso.sh
  ```
  This script:
  - ✅ Detects your existing SSO configuration
  - ✅ Creates profiles for all environments (tar-dev, tar-staging, etc.)
  - ✅ Tests authentication for each profile
  - ✅ Provides troubleshooting guidance

#### Option 2: Manual SSO Setup (Current/Existing Projects)

For **existing projects** where users are already created manually:

- [ ] **Access IAM Identity Center console**
- [ ] **Verify Identity Center is enabled**
- [ ] **Create Permission Sets:**
  - [ ] `DeveloperAccess` with `PowerUserAccess` policy
  - [ ] `AdminAccess` with `AdministratorAccess` policy
  - [ ] `ReadOnlyAccess` with `ReadOnlyAccess` policy
- [ ] **Assign users to accounts with correct permission sets**
- [ ] **Configure CLI access for each environment:**
  ```bash
  # Create profiles for each workload account
  aws configure sso --profile tar-dev      # Development account
  aws configure sso --profile tar-staging  # Staging account
  aws configure sso --profile tar-shared   # Shared services account
  aws configure sso --profile tar-prod     # Production account
  ```

#### SSO Profile Verification

- [ ] **Test all SSO profiles:**
  ```bash
  # Test each profile
  aws sts get-caller-identity --profile tar-dev
  aws sts get-caller-identity --profile tar-staging
  aws sts get-caller-identity --profile tar-shared
  aws sts get-caller-identity --profile tar-prod
  ```

- [ ] **Run automated setup helper** (if you have manual users):
  ```bash
  ./scripts/setup-automated-sso.sh
  # Will detect existing SSO config and create missing profiles
  ```

#### Troubleshooting: "No access" errors after profile creation

If you get "No access" errors when testing profiles, it means users haven't been assigned to permission sets:

**Option A: Automated Helper (Shows Your Exact Steps):**

```bash
./scripts/show-manual-steps.sh
```
This script displays the exact steps with your specific account IDs and email addresses. Follow the output in your browser.

**Option B: Manual Steps:**

1. **Go to [IAM Identity Center Console](<https://console.aws.amazon.com/singlesignon)**>

2. **Create Permission Set (if not exists):**
   - Multi-account permissions → Permission sets → **Create permission set**
   - Name: `AdminAccess`
   - Use predefined permission set: `AdministratorAccess`
   - Click **Create**

3. **Assign Users to Accounts:**
   - AWS accounts → **Select your Dev account** → **Assign users or groups**
   - Select: `testawsrahardja+dev@gmail.com` → **Next**
   - Select: `AdminAccess` permission set → **Next** → **Submit**
   - Repeat for:
     - Staging account → `testawsrahardja+staging@gmail.com`
     - Shared account → `testawsrahardja+shared@gmail.com`
     - Production account → `testawsrahardja+prod@gmail.com`

4. **Wait for provisioning** (2-3 minutes per assignment)

5. **Test the profiles:**
   ```bash
   # Test each profile after assignment
   aws sts get-caller-identity --profile tar-dev
   aws sts get-caller-identity --profile tar-staging
   aws sts get-caller-identity --profile tar-shared
   aws sts get-caller-identity --profile tar-prod
   ```

**Expected output:** Should show the account ID and assumed role ARN for each environment.

**⏱️ Time:** 5-10 minutes for manual assignment of all 4 environments.

**Option C: Full Automation (Advanced):**

For the technically adventurous, try the full automation script:
```bash
BASE_EMAIL=testawsrahardja@gmail.com ./scripts/assign-sso-permissions.sh
```
⚠️ This script may have regional/permission issues but automates the entire process if it works.

---

## ✅ Phase 6: CDK Application Code

### 6.1 TypeScript Lambda Functions

- [ ] **Create `lib/lambda/main-handler.ts`** with the following content:

```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';

interface ResponseMetadata {
  remainingTime: number;
  memoryLimit: string;
  architecture: string;
  nodeVersion: string;
}

interface ResponseBody {
  message: string;
  environment: string;
  account: string;
  timestamp: string;
  requestId: string;
  region: string;
  version: string;
  runtime: string;
  metadata: ResponseMetadata;
}

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  // Log incoming request for debugging and monitoring
  console.log('event received:', JSON.stringify(event, null, 2));

  const responseBody: ResponseBody = {
    message: process.env.HELLO_WORLD_MESSAGE || 'Hello World!',
    environment: process.env.ENVIRONMENT || 'unknown',
    account: process.env.ACCOUNT_NAME || 'unknown',
    timestamp: new Date().toISOString(),
    requestId: context.awsRequestId,
    region: process.env.AWS_REGION || 'unknown',
    version: '1.0.0',
    runtime: 'nodejs22.x',
    // 🇸🇬 Singapore addition: add location metadata
    // location: {
    //   country: 'singapore',
    //   region: 'ap-southeast-1',
    //   timezone: 'asia/singapore',
    //   localtime: new Date().toLocaleString('en-sg', {
    //     timeZone: 'asia/singapore'
    //   })
    // },
    metadata: {
      remainingTime: context.getRemainingTimeInMillis(),
      memoryLimit: context.memoryLimitInMB,
      architecture: process.arch,
      nodeVersion: process.version
    }
  };

  const response: APIGatewayProxyResult = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
    body: JSON.stringify(responseBody, null, 2)
  };

  return response;
};
```

- [ ] **Create `lib/lambda/health-handler.ts`** with the following content:

```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';

interface HealthResponseBody {
  status: string;
  environment: string;
  timestamp: string;
  uptime: number;
}

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {

  const responseBody: HealthResponseBody = {
    status: 'healthy',
    environment: process.env.ENVIRONMENT || 'unknown',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  };

  const response: APIGatewayProxyResult = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(responseBody)
  };

  return response;
};
```

### 6.2 Hello World Application Construct

- [ ] **Create `lib/constructs/hello-world-app.ts`** with the following content:

```typescript
import { Construct } from "constructs";
import {
  aws_lambda as lambda,
  aws_lambda_nodejs as nodejs,
  aws_apigatewayv2 as apigatewayv2,
  aws_apigatewayv2_integrations as integrations,
  aws_logs as logs,
  CfnOutput,
  Duration,
  RemovalPolicy,
} from "aws-cdk-lib";
import { accountconfig } from "../config/accounts";

export interface helloworldappprops {
  accountconfig: accountconfig;
}

export class helloworldapp extends Construct {
  public readonly api: apigatewayv2.HttpApi;
  public readonly lambda: lambda.IFunction;

  constructor(scope: Construct, id: string, props: helloworldappprops) {
    super(scope, id);

    const { accountconfig } = props;

    // create log group with cost-optimized retention
    const loggroup = new logs.LogGroup(this, "helloworldloggroup", {
      logGroupName: `/aws/lambda/hello-world-${accountconfig.environment}`,
      retention:
        accountconfig.environment === "prod"
          ? logs.RetentionDays.ONE_MONTH
          : logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY, // cost optimization
    });

    // create TypeScript lambda function with automatic compilation
    this.lambda = new nodejs.NodejsFunction(this, "helloworldfunction", {
      runtime: lambda.Runtime.NODEJS_22_X,
      entry: "lib/lambda/main-handler.ts",   // TypeScript source file
      handler: "handler",                    // Export name from TypeScript file
      environment: {
        ENVIRONMENT: accountconfig.environment,
        ACCOUNT_NAME: accountconfig.name,
        HELLO_WORLD_MESSAGE: accountconfig.helloworldmessage,
      },
      description: `Hello World Lambda for ${accountconfig.name} environment`,
      timeout: Duration.seconds(accountconfig.timeout),
      memorySize: accountconfig.memorysize,
      logGroup: loggroup,
      architecture: lambda.Architecture.ARM_64, // cost optimization with graviton
      bundling: {
        minify: true,                          // Minify TypeScript output
        sourceMap: false,                      // Disable source maps for production
        target: "es2022",                      // Target modern JavaScript
      },
    });

    // create http api (cost-optimized vs rest api)
    this.api = new apigatewayv2.HttpApi(this, "helloworldapi", {
      apiName: `Hello World API - ${accountconfig.environment}`,
      description: `Hello World HTTP API for ${accountconfig.name} environment`,
      corsPreflight: {
        allowOrigins: ["*"],
        allowMethods: [
          apigatewayv2.CorsHttpMethod.GET,
          apigatewayv2.CorsHttpMethod.POST,
        ],
        allowHeaders: ["Content-Type", "Authorization"],
        maxAge: Duration.days(1),
      },
    });

    // add main route
    this.api.addRoutes({
      path: "/",
      methods: [apigatewayv2.HttpMethod.GET],
      integration: new integrations.HttpLambdaIntegration(
        "rootintegration",
        this.lambda,
      ),
    });

    // simple health check endpoint with TypeScript
    const healthlambda = new nodejs.NodejsFunction(this, "healthfunction", {
      runtime: lambda.Runtime.NODEJS_22_X,
      entry: "lib/lambda/health-handler.ts",  // TypeScript source file
      handler: "handler",                     // Export name from TypeScript file
      environment: {
        ENVIRONMENT: accountconfig.environment,
      },
      timeout: Duration.seconds(10),
      memorySize: 128, // minimal for health check
      architecture: lambda.Architecture.ARM_64,
      bundling: {
        minify: true,                          // Minify TypeScript output
        sourceMap: false,                      // Disable source maps for production
        target: "es2022",                      // Target modern JavaScript
      },
    });

    this.api.addRoutes({
      path: "/health",
      methods: [apigatewayv2.HttpMethod.GET],
      integration: new integrations.HttpLambdaIntegration(
        "healthintegration",
        healthlambda,
      ),
    });

    // outputs
    new CfnOutput(this, "apiurl", {
      value: this.api.apiEndpoint,
      description: `Hello World API URL for ${accountconfig.environment}`,
      exportName: `helloworldapiurl-${accountconfig.environment}`,
    });

    new CfnOutput(this, "healthcheckurl", {
      value: `${this.api.apiEndpoint}/health`,
      description: `Health check URL for ${accountconfig.environment}`,
    });
  }
}
```

### 6.3 Create Application Stack

- [ ] **Create `lib/stacks/application-stack.ts`** with the following content:

```typescript
import { Stack, StackProps, Tags } from "aws-cdk-lib";
import { Construct } from "constructs";
import { helloworldapp } from "../constructs/hello-world-app";
import { accountconfig } from "../config/accounts";

export interface applicationstackprops extends StackProps {
  accountconfig: accountconfig;
}

export class applicationstack extends Stack {
  constructor(scope: Construct, id: string, props: applicationstackprops) {
    super(scope, id, props);

    const { accountconfig } = props;

    // create hello world application
    new helloworldapp(this, "helloworldapp", {
      accountconfig,
    });

    // add tags
    Tags.of(this).add("environment", accountconfig.environment);
    Tags.of(this).add("managedby", "cdk");
    Tags.of(this).add("project", "simplecontroltower");
  }
}
```

---

### 6.4 Update Main CDK App

- [ ] **Update `bin/simple-control-tower-cdk.ts`** with the following content:

```typescript
#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { applicationstack } from "../lib/stacks/application-stack";
import { accounts } from "../lib/config/accounts";

const app = new cdk.App();

// deploy application stacks for each environment
Object.entries(accounts).forEach(([key, accountconfig]) => {
  new applicationstack(app, `helloworld-${key}`, {
    accountconfig: accountconfig,
    env: {
      account:
        process.env[`${key.toUpperCase()}_ACCOUNT_ID`] ||
        process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || "us-east-1",
      // 🇸🇬 singapore: change to "ap-southeast-1"
    },
    description: `hello world application for ${accountconfig.name} environment`,
    // 🇸🇬 singapore: add "(singapore)" to description
    stackName: `helloworld-${key}`,
  });
});

// global tags
cdk.Tags.of(app).add("managedby", "cdk");
cdk.Tags.of(app).add("project", "simplecontroltower");
// 🇸🇬 singapore additions:
// cdk.tags.of(app).add("region", "ap-southeast-1");
// cdk.tags.of(app).add("country", "singapore");
// cdk.tags.of(app).add("currency", "sgd");
```

---

## 🚀 TypeScript Lambda Benefits

This template now uses **TypeScript Lambda functions** with the following advantages:

### ✅ **Type Safety & Development Experience**
- **Compile-time error checking** prevents runtime errors
- **IntelliSense support** with autocomplete and documentation
- **Refactoring safety** with IDE support for renaming and finding references
- **Interface definitions** for request/response structures

### ✅ **Automatic Build & Optimization**
- **NodejsFunction** automatically compiles TypeScript to JavaScript
- **esbuild integration** for fast compilation and minification
- **Tree shaking** removes unused code for smaller bundles
- **Modern JavaScript targets** (ES2022) for better performance

### ✅ **External File Organization**
- **Separate .ts files** instead of inline code for better maintainability
- **Proper IDE support** with syntax highlighting and debugging
- **Version control friendly** with clean file structure
- **Easier testing** with external TypeScript files

### ✅ **Bundle Optimization**
- **Minified output** for reduced Lambda cold start times
- **No source maps** in production for smaller bundles
- **ARM64 optimization** combined with TypeScript compilation
- **Modern JavaScript** targeting for better performance

### 🔄 **Migration from JavaScript**
If you previously used inline JavaScript:
- Replace `lambda.Code.fromInline()` with TypeScript files
- Change `lambda.Function` to `nodejs.NodejsFunction`
- Add proper TypeScript types for better development experience
- Enjoy automatic compilation and optimization

---

## ✅ Phase 7: Deployment Scripts

### 7.1 Get Account IDs Script

- [ ] **Create `scripts/get-account-ids.sh`** with the following content:

```bash
#!/bin/bash

# Script Purpose: Retrieve AWS account IDs from Control Tower deployment
# This script queries AWS Organizations to get the numeric account IDs for all
# workload accounts created by Control Tower, then stores them in a .env file
# for use by other deployment scripts (bootstrap, deploy, etc.)

echo "🔍 getting account ids from control tower deployment..."
# 🇸🇬 singapore: this script works the same regardless of region

# Function to query AWS Organizations and get account ID by account name
# Takes account name as parameter and returns the numeric account ID
get_account_id() {
local account_name="$1"
# Query AWS Organizations API to list all accounts in the organization
# Filter by account name and return only the account ID
aws organizations list-accounts \
--query "accounts[?name=='$account_name'].id" \
--output text 2>/dev/null
}

# Query each workload account created by Control Tower
# These names must match exactly what was used during Control Tower account creation
prod_account=$(get_account_id "production")
staging_account=$(get_account_id "staging")
dev_account=$(get_account_id "development")
shared_account=$(get_account_id "shared-services")

# Create .env file with all account IDs for use by other scripts
# This file will be sourced by bootstrap-accounts.sh and deploy-applications.sh
cat > .env << eof
# account ids (generated $(date))
# These variables are used by CDK deployment scripts to target specific accounts
prod_account_id=$prod_account
staging_account_id=$staging_account
dev_account_id=$dev_account
shared_account_id=$shared_account

# management account (the account you're currently logged into)
# This is used for cross-account trust relationships during CDK bootstrap
management_account_id=$(aws sts get-caller-identity --query account --output text)

# 🇸🇬 singapore additions:
# aws_region=ap-southeast-1
# aws_default_region=ap-southeast-1
# country=singapore
# timezone=asia/singapore
# currency=sgd
eof

# Display summary of found account IDs for verification
echo "📋 account ids found:"
echo "├── management: $(aws sts get-caller-identity --query account --output text)"
echo "├── production: $prod_account"
echo "├── staging: $staging_account"
echo "├── development: $dev_account"
echo "└── shared services: $shared_account"

echo "💾 account ids saved to .env file"
```

### 7.2 Bootstrap Accounts Script

- [ ] **Create `scripts/bootstrap-accounts.sh`** with the following content:

```bash
#!/bin/bash

# load environment variables
source .env

echo "🔧 cdk bootstrap process"
echo "========================"
# 🇸🇬 singapore: update title to "cdk bootstrap process (singapore)"

# function to bootstrap account
bootstrap_account() {
local account_id="$1"
local account_name="$2"

echo "🚀 bootstrapping $account_name ($account_id)..."
# 🇸🇬 singapore: add "in singapore" to the message

cdk bootstrap aws://$account_id/$aws_default_region \
--qualifier "cdk2024" \
--toolkit-stack-name "cdktoolkit" \
--cloudformation-execution-policies "arn:aws:iam::aws:policy/administratoraccess" \
--trust-accounts $management_account_id
# 🇸🇬 singapore additions:
# --tags region=ap-southeast-1 \
# --tags country=singapore

if [ $? -eq 0 ]; then
echo "✅ $account_name bootstrapped successfully"
# 🇸🇬 singapore: add "in singapore" to success message
else
echo "❌ failed to bootstrap $account_name"
return 1
fi
}

# bootstrap all accounts
bootstrap_account $dev_account "development"
bootstrap_account $staging_account "staging"
bootstrap_account $shared_account "shared services"
bootstrap_account $prod_account "production"

echo "✅ all accounts bootstrapped successfully!"
```

### 7.3 Deploy Applications Script

- [ ] **Create `scripts/deploy-applications.sh`** with the following content:

```bash
#!/bin/bash

# load environment variables
source .env

echo "🚀 deploying hello world applications"
echo "===================================="
# 🇸🇬 singapore: update title to include "(singapore)"

# function to deploy to specific account
deploy_to_account() {
local env_name="$1"
local account_id="$2"
local stack_name="helloworld-$env_name"

echo "📦 deploying $stack_name to account $account_id..."
# 🇸🇬 singapore: add "in singapore" to deployment message

cdk deploy $stack_name \
--context accountid=$account_id \
--require-approval never \
--outputs-file "outputs-$env_name.json"

if [ $? -eq 0 ]; then
echo "✅ $stack_name deployed successfully"

# extract and test api url
api_url=$(cat "outputs-$env_name.json" | jq -r ".[\"$stack_name\"].apiurl" 2>/dev/null)
if [ "$api_url" != "null" ] && [ ! -z "$api_url" ]; then
echo "🌐 api url: $api_url"

# test the endpoint
echo "🧪 testing endpoint..."
response=$(curl -s "$api_url" 2>/dev/null)
if echo "$response" | grep -q "hello"; then
echo "✅ endpoint test successful"
else
echo "⚠️  endpoint test failed"
fi
fi
else
echo "❌ failed to deploy $stack_name"
return 1
fi
echo ""
}

# deploy to each environment (dev -> staging -> shared -> prod)
deploy_to_account "dev" $dev_account
deploy_to_account "staging" $staging_account
deploy_to_account "shared" $shared_account
deploy_to_account "prod" $prod_account

echo "🎉 all applications deployed successfully!"
echo ""
echo "🔗 access your applications:"
for env in dev staging shared prod; do
if [ -f "outputs-$env.json" ]; then
url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
echo "├── $env: $url"
fi
done
```

### 7.4 Validation Script

- [ ] **Create `scripts/validate-deployment.sh`** with the following content:

```bash
#!/bin/bash

echo "🔍 comprehensive deployment validation"
echo "======================================"
# 🇸🇬 singapore: add "(singapore)" to title

# load environment variables
source .env 2>/dev/null || echo "⚠️  .env file not found"

# check cdk version
cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
echo "✅ cdk version: $cdk_version"
else
echo "❌ cdk version: $cdk_version (expected cdk v2)"
fi

# check node.js version
node_version=$(node --version 2>/dev/null)
if echo "$node_version" | grep -qe "v(20|22)\."; then
echo "✅ node.js version: $node_version"
else
echo "⚠️  node.js version: $node_version (recommended: v20+ or v22+)"
fi

# test applications
environments=("dev" "staging" "shared" "prod")

for env in "${environments[@]}"; do
echo ""
echo "🧪 testing $env environment..."

# get api url
api_url=""
if [ -f "outputs-$env.json" ]; then
api_url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
fi

if [ ! -z "$api_url" ] && [ "$api_url" != "null" ]; then
echo "🌐 api url: $api_url"

# test main endpoint
response=$(curl -s --max-time 10 "$api_url" 2>/dev/null)
if echo "$response" | grep -q "hello"; then
echo "✅ main endpoint working"

# extract environment from response
env_from_response=$(echo "$response" | jq -r '.environment' 2>/dev/null)
if [ "$env_from_response" = "$env" ]; then
echo "✅ environment validation passed"
else
echo "⚠️  environment mismatch: expected $env, got $env_from_response"
fi
else
echo "❌ main endpoint test failed"
fi

# test health endpoint
health_url="${api_url%/}/health"
health_response=$(curl -s --max-time 10 "$health_url" 2>/dev/null)
if echo "$health_response" | grep -q "healthy"; then
echo "✅ health endpoint working"
else
echo "⚠️  health endpoint test failed"
fi
else
echo "❌ stack not found or not deployed: helloworld-$env"
fi
done

echo ""
echo "📊 validation summary"
echo "===================="
echo "✅ validation completed at $(date)"
echo ""
echo "🚀 next steps:"
echo "1. access your hello world applications using the urls above"
echo "2. monitor costs in aws cost explorer"
echo "3. set up ci/cd pipeline: dev → staging → prod"
echo "4. add your custom applications to each environment"
```

---

### 7.5 Complete Setup Script

- [ ] **Create `scripts/complete-setup.sh`** with the following content:

```bash
#!/bin/bash

set -e

echo "🚀 complete simple control tower + cdk v2 setup"
echo "==============================================="
# 🇸🇬 singapore: update title to include "(singapore edition)"

# step 1: prerequisites
echo "📋 step 1: checking prerequisites..."
# 🇸🇬 singapore: add region verification step here

node_version=$(node --version)
if echo "$node_version" | grep -qe "v(20|22)\."; then
echo "✅ node.js version: $node_version"
else
echo "❌ node.js version $node_version not supported. need v20+ or v22+"
exit 1
fi

cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
echo "✅ cdk version: $cdk_version"
else
echo "❌ cdk version $cdk_version not supported. need cdk v2"
exit 1
fi

# step 2: build project
echo "📋 step 2: building project..."
npm run build

if [ $? -eq 0 ]; then
echo "✅ project built successfully"
else
echo "❌ project build failed"
exit 1
fi

# step 3: synthesize cdk
echo "📋 step 3: synthesizing cdk..."
cdk synth

if [ $? -eq 0 ]; then
echo "✅ cdk synthesis completed"
else
echo "❌ cdk synthesis failed"
exit 1
fi

# step 4: check control tower
echo "📋 step 4: checking control tower status..."

# note: this requires control tower to be manually set up first
echo "⚠️  manual setup required:"
echo "1. go to aws control tower console"
# 🇸🇬 singapore: add specific url
# echo "1. go to: <https://ap-southeast-1.console.aws.amazon.com/controltower/">
echo "2. click 'set up landing zone'"
# 🇸🇬 singapore: add region selection step
# echo "3. select home region: asia pacific (singapore) ap-southeast-1"
# echo "4. optional: add sydney (ap-southeast-2) for disaster recovery"
echo "3. configure with your email addresses from accounts.ts"
echo "4. wait for setup to complete (30-45 minutes)"
echo "5. re-run this script after control tower is ready"

# check if control tower is available
aws controltower list-landing-zones 2>/dev/null >/dev/null
if [ $? -eq 0 ]; then
echo "✅ control tower cli access confirmed"
else
echo "⚠️  control tower not available yet"
echo "continue with manual setup and run the remaining steps manually"
fi

# step 5: get account ids
echo "📋 step 5: getting account ids..."
./scripts/get-account-ids.sh

# step 6: bootstrap accounts
echo "📋 step 6: bootstrapping accounts..."
./scripts/bootstrap-accounts.sh

# step 7: deploy applications
echo "📋 step 7: deploying applications..."
./scripts/deploy-applications.sh

# step 8: validate
echo "📋 step 8: validating deployment..."
./scripts/validate-deployment.sh

echo ""
echo "🎉 simple control tower + cdk v2 setup complete!"
echo ""
echo "📊 what was deployed:"
echo "├── 💻 development: cost-optimized, minimal resources"
echo "├── 🧪 staging: pre-production testing"
echo "├── 🔧 shared services: shared resources"
echo "└── 🚀 production: full resources"
echo ""
echo "🔗 your hello world applications:"
for env in dev staging shared prod; do
if [ -f "outputs-$env.json" ]; then
url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
echo "├── $env: $url"
fi
done
```

---

### 7.6 Update Package.json Scripts

- [ ] **Update `package.json`** to include deployment scripts:

```json
{
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "test": "jest",
    "cdk": "cdk",
    "synth": "cdk synth",
    "deploy": "cdk deploy",
    "destroy": "cdk destroy",
    "diff": "cdk diff",
    "validate": "npm run build && npm run test && cdk synth",
    "bootstrap": "cdk bootstrap",
    "deploy:dev": "cdk deploy helloworld-dev --require-approval never",
    "deploy:staging": "cdk deploy helloworld-staging --require-approval never",
    "deploy:prod": "cdk deploy helloworld-prod --require-approval never",
    "deploy:shared": "cdk deploy helloworld-shared --require-approval never",
    "deploy:all": "npm run deploy:dev && npm run deploy:staging && npm run deploy:shared && npm run deploy:prod",
    "test:endpoints": "./scripts/validate-deployment.sh",
    "setup:complete": "./scripts/complete-setup.sh"
  }
}
```

---

---

## ✅ Phase 8: Execution Commands

### 8.1 Make Scripts Executable

- [ ] **Make all scripts executable**
  ```bash
  chmod +x scripts/*.sh
  ```

### 8.2 Critical: Check for Missing Configuration

- [ ] **🚨 FIRST: Check if you're missing critical cost controls**
  ```bash
  ./scripts/fix-missing-controltower-config.sh
  ```

> **⚠️ CRITICAL**: If you went through Control Tower setup with defaults, you may be missing billing alerts and budgets. This script checks and fixes missing HIGH PRIORITY features that prevent cost disasters.

### 8.3 Update Email Configuration

- [ ] **Get account IDs and automatically update configuration**
  ```bash
  ./scripts/get-account-ids.sh
  ./scripts/sync-account-emails.sh
  ```

> **Note**: The sync script now automatically updates `lib/config/accounts.ts` with the correct emails from your AWS organization. It creates a backup file first for safety.

### 8.4 CDK Bootstrap and Deploy

- [ ] **Bootstrap CDK in management account**
  ```bash
  cdk bootstrap
  ```

- [ ] **Bootstrap all workload accounts**
  ```bash
  source .env
  ./scripts/bootstrap-accounts.sh
  ```

- [ ] **Build and synthesize CDK**
  ```bash
  npm run build
  cdk synth
  ```

- [ ] **Deploy applications to all environments**
  ```bash
  ./scripts/deploy-applications.sh
  ```

- [ ] **Validate deployment**
  ```bash
  ./scripts/validate-deployment.sh
  ```

### 8.5 Alternative: Complete Automated Setup

- [ ] **Run complete setup script** (after Control Tower manual setup)
  ```bash
  npm run setup:complete
  ```

> **Note**: This automated approach now includes automatic email synchronization, so no manual configuration updates are needed.

### 8.6 Individual Environment Commands

- [ ] **Deploy to specific environments** (optional)
  ```bash
  npm run deploy:dev
  npm run deploy:staging
  npm run deploy:shared
  npm run deploy:prod
  ```

- [ ] **Test all endpoints**
  ```bash
  npm run test:endpoints
  ```

### 8.7 Greenfield Setup Verification

**🎯 Best Practice: Single Verification Command**
```bash
# Complete setup verification (automated)
AWS_PROFILE=your-profile ./scripts/verify-complete-setup.sh
```

**Expected Output: "✅ ALL SYSTEMS READY"**

---

### **📋 Manual Verification Checklist (If Needed)**

**🚨 CRITICAL: Cost Protection**
- [ ] **6 CloudWatch alarms** with SGD thresholds
- [ ] **6 AWS budgets** with USD amounts
- [ ] **Email confirmations** clicked in your inbox
- [ ] **SNS subscriptions** all confirmed (not pending)

**📋 System Setup**
- [ ] **5+ AWS accounts** provisioned (Dev, Staging, Shared, Prod + core accounts)
- [ ] **Applications deployed** to all environments
- [ ] **API endpoints** responding correctly
- [ ] **Cost protection active** and monitoring

**🔍 Quick Manual Verification Commands**
```bash
# Verify cost protection (should show 6 alarms)
AWS_PROFILE=your-profile aws cloudwatch describe-alarms --query 'MetricAlarms[?MetricName==`EstimatedCharges`] | length(@)'

# Verify budgets (should show 6 budgets)
AWS_PROFILE=your-profile aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text) --query 'length(Budgets)'

# Test application endpoints
AWS_PROFILE=your-profile ./scripts/test-all-endpoints.sh
```

### **✅ Success Criteria**
- **6 billing alarms** monitoring all accounts
- **6 budgets** with appropriate thresholds
- **All email subscriptions confirmed**
- **Applications deployed and tested**
- **Zero manual configuration needed**

> **🎯 Modern Standard**: If you used the automated setup, everything should "just work" with minimal verification needed.

---

## 📋 Quick Reference Commands

### Security Verification

```bash
# Verify you're using IAM user (not root)
aws sts get-caller-identity
# Should show: "arn:aws:iam::account:user/control-tower-admin"
# NOT: "arn:aws:iam::account:root"
```

### Project Setup

```bash
mkdir simple-control-tower-cdk
cd simple-control-tower-cdk
cdk init app --language typescript
npm install aws-cdk-lib@latest constructs@latest
```

## 🚀 Greenfield Setup Commands

### **🎯 New Best Practice: Single Command Setup**

**After Control Tower setup completes:**

#### **Complete Environment Setup (Recommended)**
```bash
# ONE command does everything:
./scripts/setup-complete-environment.sh

# This automatically handles:
# ✅ Account discovery
# ✅ SSO setup and user assignments
# ✅ Profile creation (tar-dev, tar-staging, etc.)
# ✅ CDK bootstrap in all accounts
# ✅ Validation and testing
```

#### **Alternative: Individual Steps**
```bash
# If you prefer granular control:
./scripts/get-account-ids.sh                    # Discover accounts
./scripts/setup-sso-simple.sh your@email.com   # Setup SSO
./scripts/bootstrap-accounts.sh                # Bootstrap CDK
./scripts/validate-complete-setup.sh           # Validate everything
```

#### **Validation and Testing**
```bash
# Test all SSO profiles work:
aws sts get-caller-identity --profile tar-dev
aws sts get-caller-identity --profile tar-staging
aws sts get-caller-identity --profile tar-shared
aws sts get-caller-identity --profile tar-prod

# Complete health check:
./scripts/validate-complete-setup.sh --verbose
```

#### **Application Deployment**
```bash
# After environment setup is complete:
./scripts/deploy-applications.sh

# Or build and deploy manually:
npm run build
cdk deploy --all

# Deploy to specific environment:
AWS_PROFILE=tar-dev cdk deploy helloworld-dev
```

**Total Time: ~15 minutes (including AWS provisioning time)**

#### **💰 Smart Cost Management**

**Destroy applications to save money (preserves foundation):**
```bash
# Save ~$36-120/month, keep foundation ready
./scripts/destroy-applications.sh

# Quick redeploy anytime (2 minutes)
cdk deploy --all
```

**Complete infrastructure destruction:**
```bash
# Nuclear option - destroys everything
./scripts/destroy-everything.sh

# Rebuild requires full setup
./scripts/setup-complete-environment.sh
```

**Perfect development workflow:**
```bash
# Start work day
AWS_PROFILE=tar-dev cdk deploy helloworld-dev

# End work day (save money)
./scripts/destroy-applications.sh

# Resume next day (2 minutes)
AWS_PROFILE=tar-dev cdk deploy helloworld-dev
```

**Cost breakdown:**
- **Active development**: $35-70/month
- **Savings mode**: $0.10/month (99% reduction)
- **Foundation preserved**: SSO profiles, CDK bootstrap, accounts

#### **🔧 Common Issues & Solutions**

**CDK Version Mismatch Error:**
```bash
# Error: "CLI versions and CDK library versions have diverged"
npm install -g aws-cdk@latest
```

**Applications Not Deployed:**
```bash
# Check if stacks exist
AWS_PROFILE=your-profile cdk list

# If no stacks, run the full deployment:
npm run build
source .env
AWS_PROFILE=your-profile ./scripts/bootstrap-accounts.sh
AWS_PROFILE=your-profile ./scripts/deploy-applications.sh
```

**Permission Errors:**
```bash
# Make sure you're using SSO profile, not root
aws sts get-caller-identity
# Should show IAM user, not root

# Refresh SSO login if expired
aws sso login --profile your-profile
```

---

### **⚙️ Alternative: Individual Commands (If Needed)**

**If you need granular control or troubleshooting:**

**🚨 Step 1: Cost Protection (CRITICAL - Must be First)**
```bash
# Complete cost protection setup
ALERT_EMAIL=your@email.com AWS_PROFILE=your-profile ./scripts/setup-cost-protection.sh
```

**📋 Step 2: Account Setup & Deployment**
```bash
# Account discovery and application deployment
AWS_PROFILE=your-profile ./scripts/setup-accounts-and-deploy.sh
```

**🔍 Step 3: Validation**
```bash
# Verify everything is working
AWS_PROFILE=your-profile ./scripts/validate-complete-setup.sh
```

---

### **🛠️ Individual Script Commands (Troubleshooting Only)**

<details>
<summary>Click to expand individual commands (use only for debugging)</summary>

```bash
# Cost Protection (do these first, in order)
ALERT_EMAIL=your@email.com AWS_PROFILE=your-profile ./scripts/fix-missing-controltower-config.sh
ALERT_EMAIL=your@email.com AWS_PROFILE=your-profile ./scripts/create-per-account-alerts.sh
AWS_PROFILE=your-profile ./scripts/create-budgets.sh

# Account Setup
AWS_PROFILE=your-profile ./scripts/get-account-ids.sh
AWS_PROFILE=your-profile ./scripts/sync-account-emails.sh

# CDK Setup
source .env
AWS_PROFILE=your-profile cdk bootstrap
AWS_PROFILE=your-profile ./scripts/bootstrap-accounts.sh

# Deployment
AWS_PROFILE=your-profile ./scripts/deploy-applications.sh
AWS_PROFILE=your-profile ./scripts/validate-deployment.sh
```
</details>

> **⚠️ Important**: Always use the single command approach unless you need to debug specific issues. Individual commands are provided for troubleshooting only.

### individual environment commands

```bash
# ⚠️ ensure you're using iam user credentials, not root
aws sts get-caller-identity  # should show iam user arn

# deploy to specific environment
npm run deploy:dev
npm run deploy:staging
npm run deploy:prod
npm run deploy:shared

# deploy all at once
npm run deploy:all

# test all endpoints
npm run test:endpoints

# complete automated setup (after control tower manual setup)
npm run setup:complete
```

### 🔐 security troubleshooting

```bash
# if you get permission errors:

# 1. verify you're using iam user (not root)
aws sts get-caller-identity
# should show: "arn:aws:iam::account:user/control-tower-admin"
# not: "arn:aws:iam::account:root"

# 2. check iam user has administratoraccess
aws iam list-attached-user-policies --user-name control-tower-admin

# 3. for control tower operations, you may need to assume organizationaccountaccessrole
# this is normal for cross-account operations

# 4. if cdk bootstrap fails due to scps, try:
cdk bootstrap --trust-accounts management_account_id --cloudformation-execution-policies arn:aws:iam::aws:policy/administratoraccess
```

---

## cost optimization features

this template includes several cost optimization features:

### 🏗️ **architecture choices**

- **http api** instead of rest api (up to 70% cheaper)
- **arm64 lambda** architecture (up to 20% cheaper)
- **minimal memory allocation** for dev environments

### 📊 **environment-specific sizing**

- **development**: 128mb memory, 10s timeout
- **staging**: 256mb memory, 15s timeout
- **production**: 512mb memory, 30s timeout

### 🗃️ **log retention**

- **development**: 1 week retention
- **staging**: 1 week retention
- **production**: 1 month retention

### 🏷️ **resource management**

- all resources tagged for cost tracking
- removal policy set to destroy for easy cleanup
- no unnecessary persistent resources

### 🇸🇬 **singapore pricing considerations**

- **regional difference**: singapore typically 10-15% higher than us-east-1
- **still optimized**: all cost features work the same in singapore
- **expected costs**: ~$2-20 sgd per environment for minimal usage
- **currency tracking**: add sgd tags for cost management

---

## summary

this simplified template provides:

✅ **modern cdk v2** with aws-cdk-lib
✅ **node.js 22** lambda runtime
✅ **cost-optimized** http apis and arm64 architecture
✅ **multi-environment** structure (dev/staging/prod/shared)
✅ **simple deployment** scripts
✅ **universal template** - works in any region
✅ **greenfield ready** - minimal dependencies

the template removes all singapore-specific compliance features while maintaining the solid multi-account control tower foundation you can build upon anywhere.

### 🇸🇬 quick singapore adaptation

to use this template in singapore, simply:

1. **set region**: `aws configure set region ap-southeast-1`
2. **update cdk app**: change region to `ap-southeast-1` in `bin/simple-control-tower-cdk.ts`
3. **control tower setup**: select singapore as home region in console
4. **optional**: add singapore flags to hello world messages and location metadata

all cost optimizations and architectural benefits remain the same!

### 🔐 security summary

**✅ always use iam user credentials for cli operations**

- root account: only for initial setup and emergencies
- iam user: daily operations, cdk deployments, control tower management
- mfa: enabled on both root and iam user accounts
- access keys: only on iam user, never on root account

this approach provides the same functionality with enterprise-grade security! 🚀

