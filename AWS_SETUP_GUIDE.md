# 🚀 AWS Multi-Account Setup Guide

**Complete AWS Control Tower + CDK environment from zero to production
in 90 minutes.**

---

## 🎯 What You'll Build

By following this guide, you'll create a **production-ready AWS foundation**
with:

- ✅ **7 AWS accounts** (Management, Audit, Log Archive, Dev, Staging,
  Shared, Production)
- ✅ **Enterprise governance** with AWS Control Tower guardrails
- ✅ **Multi-environment applications** with TypeScript Lambda functions
- ✅ **Working API endpoints** in all environments
- ✅ **SSO profiles** for easy account switching
- ✅ **Cost management** with 99% savings capability
- ✅ **Security baseline** with monitoring and alerts

**Live Example Endpoints After Setup:**

- Dev: <https://f2lr8yozyf.execute-api.ap-southeast-1.amazonaws.com>
- Staging: <https://l731967ade.execute-api.ap-southeast-1.amazonaws.com>
- Production: <https://eld5yg0zte.execute-api.ap-southeast-1.amazonaws.com>

---

## ⏱️ Time Investment

| Phase | Duration | Type | What Happens |
|-------|----------|------|--------------|
| **Manual Prerequisites** | 60-90 min | Manual | AWS setup, tools, CT |
| **Automated Setup** | 15 min | Automated | Discovery, SSO, CDK, deployment |
| **TOTAL** | **90 min** | **Mixed** | **Complete production environment** |

**Monthly Cost:** $35-70 USD (or $0.10 with smart cost management)

---

## 🗺️ Choose Your Path

### **👤 I'm New to AWS**

**Perfect! This guide is designed for you.**

1. **📖 Read Overview:** [CT_GUIDE.md](./docs/manual/CT_GUIDE.md) -
   Understand what you're building
2. **🛠️ Manual Setup:**
   [GREENFIELD_MANUAL_SETUP.md](./docs/manual/GREENFIELD_MANUAL_SETUP.md) -
   Step-by-step prerequisites
3. **⚡ Automation:** Run `./scripts/up.sh` - Complete environment setup
4. **🎉 Success:** Working API endpoints in all 4 environments!

**Estimated time:** 90-120 minutes for first-time AWS users

---

### **👨‍💻 I'm AWS Experienced**

**Fast track for experienced users.**

1. **📋 Quick Review:**
   [CT_GUIDE.md](./docs/manual/CT_GUIDE.md#-setup-overview-manual-vs-automated)
   - See the 2-script approach
2. **⚡ Manual Prerequisites:** Complete AWS account setup, Control Tower,
   tool installation
3. **🚀 Automated Setup:** Run `./scripts/up.sh` - Everything else automated
4. **💰 Cost Management:** Run `./scripts/down.sh` when not developing

**Estimated time:** 45-60 minutes for AWS veterans

---

### **🔧 I Want to Understand the Architecture**

**Technical deep dive for developers.**

1. **📋 Overview:** [CT_GUIDE.md](./docs/manual/CT_GUIDE.md) -
   Strategy and approach
2. **🏗️ Architecture:** [APP_FLOW.md](./docs/automated/APP_FLOW.md) -
   Technical implementation details
3. **📝 Scripts:** [SCRIPTS_README.md](./docs/automated/SCRIPTS_README.md) -
   What each script does
4. **🛠️ Setup:**
   [GREENFIELD_MANUAL_SETUP.md](./docs/manual/GREENFIELD_MANUAL_SETUP.md) -
   Prerequisites
5. **⚡ Execute:** Run `./scripts/up.sh` - Automated setup

**Best for:** Senior developers, DevOps engineers, solution architects

---

### **💰 I'm Focused on Cost Management**

**Optimize for development cost efficiency.**

1. **📊 Cost Analysis:**
   [CT_GUIDE.md](./docs/manual/CT_GUIDE.md#-total-cost--smart-savings) -
   Cost breakdown and strategy
2. **🛠️ Setup:** Complete environment setup first
3. **💸 Optimize:** Use `./scripts/down.sh` for smart cost management
   with 4 options

**Key Insight:** $35-70/month → $0.10/month with 2-minute redeploy
capability

---

## 🚀 Ultra-Quick Start (Experienced Users)

**If you just want to get running fast:**

```bash
# 1. Manual Prerequisites (30-45 minutes)
# - Create AWS account with MFA
# - Install: Node.js v20+, AWS CLI v2, CDK v2, jq
# - Run Control Tower wizard
# - Create user in IAM Identity Center
# - Clone project: git clone <repo> && cd <project> && npm install

# 2. Automated Everything (15 minutes)
./scripts/up.sh

# 3. Result: Working endpoints in 4 environments! 🎉
```

---

## 📚 Complete Documentation Index

### **🎯 Getting Started**

- **[AWS_SETUP_GUIDE.md](./AWS_SETUP_GUIDE.md)** ← You are here

### **📖 Manual Setup Documentation**

- **[CT_GUIDE.md](./docs/manual/CT_GUIDE.md)** -
  Complete setup strategy and overview
- **[GREENFIELD_MANUAL_SETUP.md](./docs/manual/GREENFIELD_MANUAL_SETUP.md)** -
  Manual prerequisites checklist

### **⚡ Automated Setup Documentation**

- **[SCRIPTS_README.md](./docs/automated/SCRIPTS_README.md)** -
  Script documentation and usage
- **[APP_FLOW.md](./docs/automated/APP_FLOW.md)** -
  Architecture and implementation details

### **🚀 Automation Scripts**

- **[scripts/up.sh](./scripts/up.sh)** - Complete environment setup
- **[scripts/down.sh](./scripts/down.sh)** - Smart cost management

---

## ⚠️ Important Prerequisites

**Before starting, ensure you have:**

### **Required Knowledge**

- Basic understanding of cloud computing concepts
- Familiarity with command line/terminal
- Email access for AWS account verification

### **Required Tools** (will be installed during setup)

- Node.js v20+
- AWS CLI v2
- AWS CDK v2
- jq JSON processor

### **Required AWS Resources**

- AWS account with billing method
- Control Tower setup completed
- IAM Identity Center enabled

**Don't have these yet?** No problem!
[GREENFIELD_MANUAL_SETUP.md](./docs/manual/GREENFIELD_MANUAL_SETUP.md)
walks you through everything step-by-step.

---

## 🎯 Success Criteria

**You'll know you're successful when:**

✅ **4 working API endpoints** (Dev, Staging, Shared, Production)
✅ **SSO profiles working** (`aws sts get-caller-identity --profile tar-dev`)
✅ **CDK deployments working** (`cdk deploy --all`)
✅ **Cost protection enabled** (budgets and alerts configured)
✅ **Smart cost management** available (`./scripts/down.sh`)

**Example successful output:**

```bash
$ curl <https://your-dev-api.execute-api.ap-southeast-1.amazonaws.com>
{
  "message": "hello from development! 💻",
  "environment": "dev",
  "account": "development"
}
```

---

## 🆘 Getting Help

### **Common Issues & Solutions**

| Issue | Solution |
|-------|----------|
| **"Control Tower not available"** | Check region support |
| **"CDK bootstrap failed"** | Verify SSO profiles work |
| **"Account creation stuck"** | Wait 60 min, check AWS Health Dashboard |
| **"SSO login not working"** | Run `aws sso login --profile tar-dev` |
| **"Applications deployment failed"** | Check: `./scripts/down.sh` option 4 |

### **Support Resources**

- **AWS Documentation:** <https://docs.aws.amazon.com/controltower/>
- **CDK Documentation:** <https://docs.aws.amazon.com/cdk/>
- **Community Support:** AWS re:Post Control Tower forums

### **Validation Tools**

```bash
# Check environment health anytime
./scripts/down.sh  # Choose option 4: Status Check

# Quick validation
aws sts get-caller-identity --profile tar-dev
cdk synth
```

---

## 🎉 What's Next After Setup?

### **Development Workflows**

```bash
# Deploy changes to specific environment
AWS_PROFILE=tar-dev cdk deploy helloworld-dev

# Deploy to all environments
cdk deploy --all

# Save costs when not developing
./scripts/down.sh  # Choose option 1: Smart Savings
```

### **Adding More Applications**

- Use the same CDK patterns in `lib/stacks/` and `lib/constructs/`
- Follow the multi-environment configuration in
  `lib/config/accounts.ts`
- Deploy with the same CDK commands

### **Cost Optimization**

- **Daily development:** Keep applications running (~$35-70/month)
- **Breaks/weekends:** Use Smart Savings (~$0.10/month,
  2-min redeploy)
- **Long breaks:** Use Deep Clean (~$0.10/month, 15-min rebuild)

### **Scaling Up**

- Add more environments by extending `accounts.ts`
- Create additional applications following the same patterns
- Set up CI/CD pipelines using the SSO profiles

---

## ✨ What Makes This Special

### **🚀 Maximum Automation**

- **18+ scripts** consolidated into **2 commands**
- **95% automation** (only AWS legal/security steps are manual)
- **Built-in validation** with 20 comprehensive checks

### **💰 Smart Cost Management**

- **99% cost reduction** capability while preserving foundation
- **2-minute redeploy** from cost savings mode
- **Multiple destruction options** for different scenarios

### **🏗️ Enterprise Ready**

- **Production-grade governance** from day 1
- **Multi-account security isolation**
- **Comprehensive monitoring and alerting**
- **Best practices** for security and compliance

### **👩‍💻 Developer Friendly**

- **TypeScript** with full IntelliSense support
- **Fast ARM64 Lambda functions**
- **Environment-aware configurations**
- **Easy debugging and testing**

---

## 🎯 Ready to Start?

**Choose your experience level and jump in:**

- **🆕 New to AWS:** Start with [CT_GUIDE.md](./docs/manual/CT_GUIDE.md)
  for the complete overview
- **⚡ Experienced:** Jump to
  [GREENFIELD_MANUAL_SETUP.md](./docs/manual/GREENFIELD_MANUAL_SETUP.md)
  for prerequisites
- **🔧 Technical Deep Dive:** Begin with
  [APP_FLOW.md](./docs/automated/APP_FLOW.md) for architecture details

**Or just dive in:**

```bash
# Complete the manual prerequisites, then:
./scripts/up.sh
```

**You're 90 minutes away from a production-ready AWS foundation!** 🚀
