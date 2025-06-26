# 📖 Manual Setup Documentation

This folder contains documentation for **manual prerequisites** that cannot be automated due to AWS security and legal requirements.

## Files in this folder:

### **[CT_GUIDE.md](./CT_GUIDE.md)** 📋
- **Complete setup strategy** and overview
- **Time estimates** and cost analysis
- **2-script approach** explanation
- **Best practices** and recommendations
- **Start here** for understanding the overall approach

### **[GREENFIELD_MANUAL_SETUP.md](./GREENFIELD_MANUAL_SETUP.md)** 🛠️
- **Step-by-step manual prerequisites** (90 minutes)
- **AWS account creation** and MFA setup
- **Tool installation** (Node.js, AWS CLI, CDK, jq)
- **Control Tower setup** wizard walkthrough
- **IAM Identity Center** configuration
- **Security best practices** and troubleshooting
- **Complete checklist** before running automation

## Usage:

1. **New users:** Read CT_GUIDE.md first for overview
2. **All users:** Follow GREENFIELD_MANUAL_SETUP.md for prerequisites
3. **After manual setup:** Run `./scripts/up.sh` for automation

These manual steps are **required** before any automation can work.