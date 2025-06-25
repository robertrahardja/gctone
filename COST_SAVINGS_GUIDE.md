# 💰 Cost Savings Guide

## 🎯 How to Destroy Deployments to Save Money

You have **3 options** for saving money, depending on how much you want to preserve:

### **Option 1: Destroy Applications Only (Recommended)**
```bash
./scripts/destroy-applications.sh
```

**💰 Saves: ~$36-120/month**
**⏱️ Time: 5 minutes**
**🔄 Redeploy time: 2 minutes**

**What gets destroyed:**
- ✅ Lambda functions (~$20-60/month saved)
- ✅ API Gateways (~$12-40/month saved)  
- ✅ CloudWatch logs (~$4-20/month saved)

**What stays (FREE/minimal cost):**
- ✅ Control Tower accounts (~$0/month)
- ✅ CDK bootstrap infrastructure (~$0.10/month)
- ✅ SSO profiles and access (~$0/month)
- ✅ IAM roles and policies (~$0/month)

**Perfect for:** Temporary cost savings while keeping foundation ready

---

### **Option 2: Destroy Everything Except Control Tower**
```bash
./scripts/destroy-everything.sh
```

**💰 Saves: ~$40-125/month**
**⏱️ Time: 15 minutes**
**🔄 Redeploy time: 15 minutes (run setup-complete-environment.sh)**

**What gets destroyed:**
- ✅ All applications
- ✅ CDK bootstrap infrastructure
- ✅ S3 buckets and assets
- ✅ Local SSO configuration

**What stays:**
- ✅ Control Tower workload accounts
- ✅ IAM Identity Center setup

**Perfect for:** Long-term shutdown while keeping accounts

---

### **Option 3: Manual Account Closure (Nuclear Option)**

**💰 Saves: ~$40-125/month**
**⏱️ Time: 60-90 days for full closure**
**🔄 Redeploy time: Full setup required**

1. Run `./scripts/destroy-everything.sh` first
2. Go to AWS Control Tower console
3. Close workload accounts manually:
   - Development (803133978889)
   - Staging (521744733620)
   - Shared Services (216665870694)  
   - Production (668427974646)

**Perfect for:** Complete shutdown of everything

---

## 💡 Smart Cost Management Strategy

### **Development Workflow:**
```bash
# During active development
cdk deploy helloworld-dev --profile tar-dev

# When done for the day/week
./scripts/destroy-applications.sh

# Resume development anytime  
cdk deploy helloworld-dev --profile tar-dev
```

### **Demo/Presentation Workflow:**
```bash
# Before demo
cdk deploy --all

# After demo
./scripts/destroy-applications.sh
```

## 📊 Cost Breakdown

### **Current Monthly Costs:**
| Component | Monthly Cost |
|-----------|-------------|
| **Lambda functions (4 envs)** | $5-15 each = $20-60 |
| **API Gateways (4 envs)** | $3-10 each = $12-40 |
| **CloudWatch logs** | $1-5 each = $4-20 |
| **CDK S3 buckets** | $0.02-0.05 each = $0.10 |
| **Control Tower base** | $0 (included) |
| **IAM resources** | $0 (free tier) |
| **TOTAL** | **$36-120/month** |

### **After destroying applications:**
| Component | Monthly Cost |
|-----------|-------------|
| **CDK S3 buckets (empty)** | $0.02-0.05 each = $0.10 |
| **Control Tower base** | $0 (included) |
| **IAM resources** | $0 (free tier) |
| **TOTAL** | **~$0.10/month** |

## 🚀 Quick Commands Reference

### **Cost Savings Commands:**
```bash
# Destroy just applications (recommended)
./scripts/destroy-applications.sh

# Destroy everything (nuclear option)
./scripts/destroy-everything.sh

# Check what's running
./scripts/validate-complete-setup.sh
```

### **Redeploy Commands:**
```bash
# Redeploy applications (if foundation exists)
npm run build
cdk deploy --all

# Full setup (if everything destroyed)
./scripts/setup-complete-environment.sh
```

### **Monitoring Commands:**
```bash
# Check current costs
aws ce get-cost-and-usage --time-period Start=2025-06-01,End=2025-06-30 --granularity MONTHLY --metrics BlendedCost

# List all stacks
aws cloudformation list-stacks --profile tar-dev --region ap-southeast-1

# Check Lambda functions
aws lambda list-functions --profile tar-dev --region ap-southeast-1
```

## 💡 Pro Tips

### **For Learning/Development:**
- Use **Option 1** (destroy applications only)
- Keep the foundation ready for quick redeploys
- Perfect for stop/start development cycles

### **For Long-term Storage:**
- Use **Option 2** (destroy everything except accounts)
- Preserves account structure for future use
- Minimal cost (~$0.10/month)

### **For Complete Cleanup:**
- Use **Option 3** (close accounts)
- Only if you're completely done
- Requires full setup to restart

## ⚡ Time Comparisons

| Action | Time Required |
|--------|---------------|
| **Destroy applications** | 5 minutes |
| **Redeploy applications** | 2 minutes |
| **Destroy everything** | 15 minutes |
| **Full rebuild** | 15 minutes |
| **Close accounts** | 60-90 days |
| **Start from scratch** | 1.5 hours |

## 🎯 Recommended Approach

**For most users:** Use `./scripts/destroy-applications.sh`

**Why:**
- ✅ Saves 99% of the monthly costs
- ✅ Keeps foundation ready (SSO, CDK bootstrap)
- ✅ 2-minute redeploy anytime
- ✅ No complex re-setup required

This gives you the best balance of cost savings and convenience!