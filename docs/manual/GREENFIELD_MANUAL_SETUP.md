# 🌱 Greenfield Manual Setup Guide

## Prerequisites That Cannot Be Automated

These steps **MUST** be completed manually before running `./scripts/up.sh`.
AWS security and legal requirements prevent automation of these critical steps.

---

## 🏁 Complete Greenfield Checklist

### **Phase 1: AWS Account Foundation (30 minutes)**

#### **Step 1: AWS Root Account Setup** ⚠️ **CRITICAL**

```bash
# Cannot be automated - AWS security requirement
```

**What to do:**

1. **Create AWS account** at <https://aws.amazon.com/>

   - Use a dedicated email address (e.g., `aws-root@yourcompany.com`)
   - Provide payment method and contact information
   - Verify email and phone number

2. **Enable MFA on root account** ⚠️ **REQUIRED**

   - Go to AWS Console → Security Credentials
   - Set up MFA device (authenticator app or hardware key)
   - **Never skip this step** - root account compromise = total AWS takeover

3. **Create billing alerts** (Recommended)
   - Go to Billing → Billing Preferences
   - Enable "Receive Billing Alerts"
   - Set up CloudWatch billing alarm for $50-100

**Security Notes:**

- 🔒 Root account should **never** be used for daily operations
- 🔒 Store root credentials in secure password manager
- 🔒 Enable AWS CloudTrail in all regions

---

#### **Step 2: Initial Admin User Creation** 👤

```bash
# Cannot be automated - first user bootstrap problem
```

**What to do:**

1. **Sign in with root account** (one-time only)
2. **Go to IAM → Users → Create User**

   - Username: `admin` or your name
   - Access type: ✅ AWS Management Console access
   - Password: Auto-generated or custom (secure)
   - ✅ User must create a new password at next sign-in

3. **Attach AdministratorAccess policy**

   - Select user → Permissions → Add permissions
   - Attach policies directly
   - Search and select: `AdministratorAccess`

4. **Create access keys** (for CLI)

   - Select user → Security credentials → Create access key
   - Use case: CLI
   - Download CSV file securely

5. **Set up MFA for admin user**
   - Security credentials → Assign MFA device
   - Use authenticator app

**Security Notes:**

- 🔒 Admin user should have MFA enabled
- 🔒 Regular rotation of access keys (every 90 days)
- 🔒 Never share access keys in code or documentation

---

### **Phase 2: Development Tools Setup (15 minutes)**

#### **Step 3: Install Required Tools** 🛠️

```bash
# Local machine setup - cannot be automated remotely
```

**Required Tools:**

1. **Node.js v20+**

   ```bash
   # macOS
   brew install node

   # Windows
   # Download from https://nodejs.org/

   # Linux (Ubuntu/Debian)
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs

   # Verify
   node --version  # Should be v20.x.x or higher
   ```

2. **AWS CLI v2**

   ```bash
   # macOS
   brew install awscli

   # Windows
   # Download from https://aws.amazon.com/cli/

   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

   # Verify
   aws --version  # Should be aws-cli/2.x.x
   ```

3. **AWS CDK v2**

   ```bash
   npm install -g aws-cdk

   # Verify
   cdk --version  # Should be 2.x.x
   ```

4. **jq JSON processor**

   ```bash
   # macOS
   brew install jq

   # Windows
   # Download from https://stedolan.github.io/jq/

   # Linux
   sudo apt-get install jq

   # Verify
   jq --version
   ```

**Verification Commands:**

```bash
# Run all these to verify installation
node --version    # v20.0.0+
npm --version     # 9.0.0+
aws --version     # aws-cli/2.x.x
cdk --version     # 2.x.x
jq --version      # jq-1.6+
```

---

#### **Step 4: AWS CLI Initial Configuration** 🔧

```bash
# Initial bootstrap - cannot be automated
```

**What to do:**

1. **Configure AWS credentials**

   ```bash
   aws configure
   ```

   - AWS Access Key ID: [from Step 2]
   - AWS Secret Access Key: [from Step 2]
   - Default region: `ap-southeast-1` (or your preferred region)
   - Default output format: `json`

2. **Test access**

   ```bash
   aws sts get-caller-identity
   ```

   Should return your admin user information.

3. **Set up named profile** (recommended)

   ```bash
   aws configure --profile admin
   export AWS_PROFILE=admin
   ```

---

### **Phase 3: AWS Control Tower Setup (30 minutes)** 🏗️

#### **Step 5: Control Tower Wizard** ⚠️ **CANNOT BE AUTOMATED**

```bash
# AWS legal and organizational decisions required
```

**Why manual:**

- Legal terms acceptance required
- Organizational unit decisions
- Compliance and governance choices
- Multi-account strategy decisions

**What to do:**

1. **Go to AWS Control Tower console**

   - Search "Control Tower" in AWS Console
   - Click "Set up landing zone"

2. **Review and accept terms**

   - Read AWS Control Tower terms
   - Accept legal agreements
   - Review pricing (mostly free for basic setup)

3. **Configure organizational structure**

   - **Root OU**: Usually keep default
   - **Core OU**: For audit and logging accounts
   - **Custom OU**: Create "Workloads" for dev/staging/prod

4. **Configure core accounts**

   - **Audit account email**: `aws-audit@yourcompany.com`
   - **Log Archive account email**: `aws-logs@yourcompany.com`
   - Use unique email addresses (cannot be changed easily)

5. **Select regions**

   - **Home region**: Where you'll primarily operate
   - **Additional regions**: For compliance or disaster recovery
   - **Recommended**: Start with home region only

6. **Start setup and wait**
   - Setup takes 20-60 minutes
   - AWS creates foundational accounts
   - Deploys security guardrails
   - Sets up AWS SSO (IAM Identity Center)

**Progress Monitoring:**

- ✅ Step 1: Creating management account resources (5 min)
- ✅ Step 2: Creating core accounts (15 min)
- ✅ Step 3: Setting up governance (20 min)
- ✅ Step 4: Deploying guardrails (10 min)

---

#### **Step 6: Workload Account Creation** 🏢

```bash
# Account Factory - requires manual decisions
```

**Create 4 workload accounts:**

1. **Development Account**

   - Account name: `Development`
   - Account email: `aws-dev@yourcompany.com`
   - Organizational unit: `Workloads`

2. **Staging Account**

   - Account name: `Staging`
   - Account email: `aws-staging@yourcompany.com`
   - Organizational unit: `Workloads`

3. **Shared Services Account**

   - Account name: `Shared Services`
   - Account email: `aws-shared@yourcompany.com`
   - Organizational unit: `Workloads`

4. **Production Account**
   - Account name: `Production`
   - Account email: `aws-prod@yourcompany.com`
   - Organizational unit: `Workloads`

**How to create each account:**

1. Go to Control Tower → Account Factory
2. Click "Enroll account"
3. Fill in account details
4. Wait 5-10 minutes per account
5. Verify account appears in AWS Organizations

---

### **Phase 4: IAM Identity Center Setup (10 minutes)** 👥

#### **Step 7: Create Your User in Identity Center**

```bash
# User creation requires manual email verification
```

**What to do:**

1. **Go to IAM Identity Center**

   - AWS Console → IAM Identity Center
   - Click "Enable"

2. **Create your user**

   - Users → Add user
   - Username: Your email address
   - Email: Same as username
   - First name, Last name: Your details
   - ✅ Send an email invitation to this user

3. **Accept email invitation**

   - Check your email inbox
   - Click "Accept invitation"
   - Set up password
   - Set up MFA (recommended)

4. **Note the SSO start URL**
   - Format: `https://d-xxxxxxxxxx.awsapps.com/start`
   - You'll need this for CLI configuration

---

### **Phase 5: Project Setup (5 minutes)** 📁

#### **Step 8: Clone and Prepare Project**

```bash
# Local development setup
```

**What to do:**

1. **Clone the repository**

   ```bash
   git clone <your-repo>
   cd <project-directory>
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Build the project**

   ```bash
   npm run build
   ```

4. **Verify CDK works**

   ```bash
   cdk synth
   ```

---

## 🚀 Ready for Automation

After completing all manual steps above, you're ready to run the automated setup:

```bash
# Single command to complete the environment
./scripts/up.sh
```

This will handle:

- ✅ Account discovery
- ✅ SSO profile setup
- ✅ CDK bootstrap
- ✅ Validation and health checks
- ✅ Cost protection setup
- ✅ Application deployment (optional)

---

## ⏱️ Time Investment Summary

| Phase                      | Time            | Why Manual                    |
| -------------------------- | --------------- | ----------------------------- |
| **AWS Account Foundation** | 30 min          | Security & legal requirements |
| **Development Tools**      | 15 min          | Local machine setup           |
| **Control Tower Setup**    | 30 min          | Organizational decisions      |
| **Identity Center**        | 10 min          | Email verification required   |
| **Project Setup**          | 5 min           | Local development prep        |
| **TOTAL MANUAL**           | **90 minutes**  | **Cannot be automated**       |
| **Automated (up.sh)**      | **15 minutes**  | **Full automation**           |
| **GRAND TOTAL**            | **105 minutes** | **Complete greenfield setup** |

---

## 🔒 Security Best Practices

### **Account Security**

- ✅ Root account MFA enabled
- ✅ Admin user MFA enabled
- ✅ Unique email addresses for all accounts
- ✅ Strong passwords (12+ characters)
- ✅ Access key rotation (90 days)

### **Network Security**

- ✅ Control Tower guardrails enabled
- ✅ CloudTrail logging in all accounts
- ✅ Config rules for compliance
- ✅ Regular security reviews

### **Cost Security**

- ✅ Billing alerts enabled
- ✅ Budget limits set
- ✅ Regular cost reviews
- ✅ Automated cost optimization

---

## 🆘 Troubleshooting Manual Steps

### **Common Issues:**

#### **"Control Tower not available in my region"**

- Control Tower is available in most major regions
- Check: <https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/>
- Consider using a supported region

#### **"Email address already in use"**

- Each AWS account needs a unique email address
- Use email aliases: `aws-dev+dev@yourcompany.com`
- Or subdomains: `dev.aws@yourcompany.com`

#### **"Account creation failing"**

- Verify email addresses are unique and accessible
- Check billing information is valid
- Ensure compliance with AWS account limits

#### **"Control Tower setup stuck"**

- Setup can take up to 60 minutes
- Don't refresh or close browser
- Check AWS Health Dashboard for service issues
- Contact AWS Support if stuck >2 hours

#### **"Cannot access created accounts"**

- Verify Control Tower setup completed successfully
- Check Account Factory for account status
- Ensure SSO is enabled and configured

---

## 📞 Getting Help

### **AWS Support Resources:**

- **Documentation**: <https://docs.aws.amazon.com/controltower/>
- **Best Practices**: <https://aws.amazon.com/control-tower/faqs/>
- **Community**: <https://repost.aws/tags/TAJOBjdqz8SwiPOi6bEwcj3Q/aws-control-tower>

### **Emergency Contacts:**

- **AWS Support**: Available through AWS Console
- **Billing Issues**: AWS billing support (free)
- **Technical Issues**: AWS technical support (paid plans)

---

## ✅ Manual Setup Completion Checklist

Before running `./scripts/up.sh`, verify:

- [ ] ✅ AWS root account created with MFA
- [ ] ✅ Admin user created with MFA and AdministratorAccess
- [ ] ✅ Node.js v20+ installed and verified
- [ ] ✅ AWS CLI v2 installed and configured
- [ ] ✅ AWS CDK v2 installed globally
- [ ] ✅ jq JSON processor installed
- [ ] ✅ Control Tower setup completed successfully
- [ ] ✅ 4 workload accounts created (Dev, Staging, Shared, Prod)
- [ ] ✅ IAM Identity Center enabled with your user created
- [ ] ✅ Project cloned, dependencies installed, build successful
- [ ] ✅ CDK synth works without errors

**All green? You're ready!** 🎉

```bash
./scripts/up.sh
```

