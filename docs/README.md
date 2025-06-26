# 📚 Documentation Directory

This directory contains all project documentation organized by setup type.

## 📁 Directory Structure:

### **[manual/](./manual/)** 📖

**Manual setup requirements** - Cannot be automated due to AWS security/legal
requirements
- **[CT_GUIDE.md](./manual/CT_GUIDE.md)** - Complete setup strategy and
  overview
- **[GREENFIELD_MANUAL_SETUP.md](./manual/GREENFIELD_MANUAL_SETUP.md)** -
  Step-by-step manual prerequisites

### **[automated/](./automated/)** ⚡

**Automated setup documentation** - Technical details for script-based
automation
- **[SCRIPTS_README.md](./automated/SCRIPTS_README.md)** - Script
  documentation and usage
- **[APP_FLOW.md](./automated/APP_FLOW.md)** - Architecture and
  implementation details

### **Development Artifacts** 🔧

- **[SSO_PROFILES_SUMMARY.md](./SSO_PROFILES_SUMMARY.md)** - SSO
  configuration summary
- **[DOCUMENTATION_UPDATES.md](./DOCUMENTATION_UPDATES.md)** - Documentation
  change log
- **[SCRIPT_CONSOLIDATION.md](./SCRIPT_CONSOLIDATION.md)** - Script
  consolidation notes

## 🚀 Quick Navigation:

### **For New Users**

1. Start with **[../AWS_SETUP_GUIDE.md](../AWS_SETUP_GUIDE.md)** (project
   root)
2. Read **[manual/CT_GUIDE.md](./manual/CT_GUIDE.md)** for overview
3. Follow
   **[manual/GREENFIELD_MANUAL_SETUP.md](./manual/GREENFIELD_MANUAL_SETUP.md)**
   for setup

### **For Developers**

1. Review **[automated/SCRIPTS_README.md](./automated/SCRIPTS_README.md)**
   for script usage
2. Study **[automated/APP_FLOW.md](./automated/APP_FLOW.md)** for
   architecture

### **For Quick Reference**

- **Manual time:** 90 minutes (AWS account, tools, Control Tower)
- **Automated time:** 15 minutes (`./scripts/up.sh`)
- **Total time:** 105 minutes (zero to production)

## 🎯 Documentation Philosophy


**Manual docs** focus on **what you must do manually**
**Automated docs** focus on **how the automation works**

This separation makes it clear what requires human intervention vs. what's
handled by scripts.
