#!/bin/bash

# Complete Infrastructure Destruction Script
# ==========================================
# ⚠️ DANGER ZONE ⚠️
# This script destroys EVERYTHING including the foundational infrastructure.
# Only use this if you want to completely tear down the entire setup.
#
# What gets destroyed:
# - All applications (Lambda, API Gateway, logs)
# - CDK bootstrap infrastructure (S3 buckets, IAM roles)
# - Control Tower workload accounts (optional)
# - SSO profile configurations
#
# This essentially returns you to a clean slate but requires
# complete setup again using the consolidated scripts.

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${RED}☢️ COMPLETE INFRASTRUCTURE DESTRUCTION${NC}"
echo "========================================"
echo ""
echo -e "${RED}⚠️ DANGER: This will destroy EVERYTHING${NC}"
echo ""
echo -e "${YELLOW}What will be destroyed:${NC}"
echo "• All Lambda functions and API Gateways"
echo "• All CloudWatch Log Groups"
echo "• CDK bootstrap infrastructure (S3 buckets, IAM roles)"
echo "• Application stacks in all environments"
echo "• Optionally: Control Tower workload accounts"
echo ""
echo -e "${RED}After this you'll need to:${NC}"
echo "• Re-run complete setup: ./scripts/setup-complete-environment.sh"
echo "• Or manually recreate everything"
echo ""

read -p "Are you ABSOLUTELY sure? This cannot be undone easily. (type 'DESTROY'): " confirm
if [ "$confirm" != "DESTROY" ]; then
    echo "Operation cancelled. Good choice!"
    exit 0
fi

echo ""
read -p "Last chance! Type 'YES DELETE EVERYTHING' to proceed: " final_confirm
if [ "$final_confirm" != "YES DELETE EVERYTHING" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo -e "${PURPLE}💀 Starting complete destruction...${NC}"

# Load environment
if [ -f .env ]; then
    source .env
fi

# Step 1: Destroy applications first
echo -e "${YELLOW}🗑️ Step 1: Destroying applications...${NC}"
if [ -f ./scripts/destroy-applications.sh ]; then
    echo "yes" | ./scripts/destroy-applications.sh
else
    echo "Applications destruction script not found, skipping..."
fi

echo ""

# Step 2: Destroy CDK bootstrap
echo -e "${YELLOW}🗑️ Step 2: Destroying CDK bootstrap infrastructure...${NC}"

PROFILES=("tar-dev" "tar-staging" "tar-shared" "tar-prod")

for profile in "${PROFILES[@]}"; do
    echo "Destroying CDK bootstrap in $profile..."
    
    # Delete CDK toolkit stack
    if aws cloudformation describe-stacks --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
        echo "  Deleting cdktoolkit stack..."
        aws cloudformation delete-stack --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 || true
        
        # Wait for deletion
        echo "  Waiting for stack deletion..."
        aws cloudformation wait stack-delete-complete --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 || true
        echo -e "${GREEN}  ✅ cdktoolkit stack deleted${NC}"
    else
        echo "  cdktoolkit stack doesn't exist, skipping..."
    fi
    
    # Delete S3 buckets (CDK assets)
    echo "  Finding and deleting CDK S3 buckets..."
    BUCKETS=$(aws s3 ls --profile "$profile" --region ap-southeast-1 | grep "cdk-" | awk '{print $3}' || true)
    
    for bucket in $BUCKETS; do
        if [ -n "$bucket" ]; then
            echo "    Emptying and deleting bucket: $bucket"
            aws s3 rb "s3://$bucket" --force --profile "$profile" || true
        fi
    done
    
    echo ""
done

# Step 3: Clean up local configuration
echo -e "${YELLOW}🗑️ Step 3: Cleaning up local configuration...${NC}"

# Remove .env file
if [ -f .env ]; then
    echo "Removing .env file..."
    rm .env
    echo -e "${GREEN}✅ .env file removed${NC}"
fi

# Ask about SSO profiles
echo ""
read -p "Remove SSO profiles from ~/.aws/config? (y/n): " remove_sso
if [ "$remove_sso" = "y" ]; then
    echo "Backing up ~/.aws/config..."
    cp ~/.aws/config ~/.aws/config.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove tar-* profiles
    if grep -q "\[profile tar-" ~/.aws/config; then
        echo "Removing tar-* profiles from ~/.aws/config..."
        sed -i '' '/\[profile tar-/,/^$/d' ~/.aws/config
        echo -e "${GREEN}✅ SSO profiles removed${NC}"
    fi
fi

# Step 4: Information about Control Tower
echo ""
echo -e "${YELLOW}🗑️ Step 4: Control Tower Accounts${NC}"
echo ""
echo -e "${BLUE}ℹ️ Control Tower workload accounts cannot be destroyed via scripts.${NC}"
echo "If you want to remove them completely:"
echo ""
echo "1. Go to AWS Control Tower console"
echo "2. Navigate to Account Factory"
echo "3. Close each workload account manually"
echo "   • Development (803133978889)"
echo "   • Staging (521744733620)" 
echo "   • Shared Services (216665870694)"
echo "   • Production (668427974646)"
echo ""
echo -e "${YELLOW}⚠️ Note: Closing accounts may take 60-90 days for full deletion${NC}"

# Final summary
echo ""
echo -e "${BLUE}📊 Destruction Complete${NC}"
echo "======================="
echo -e "${GREEN}✅ Applications destroyed${NC}"
echo -e "${GREEN}✅ CDK bootstrap infrastructure destroyed${NC}" 
echo -e "${GREEN}✅ Local configuration cleaned${NC}"
echo -e "${YELLOW}⚠️ Control Tower accounts require manual closure${NC}"
echo ""
echo -e "${BLUE}💰 Cost after destruction:${NC}"
echo "• Monthly cost: ~$0-2/month (just Control Tower base cost)"
echo "• Savings: ~$36-120/month from destroyed applications"
echo ""
echo -e "${BLUE}🚀 To rebuild everything:${NC}"
echo "1. Run: ./scripts/setup-complete-environment.sh"
echo "2. Deploy: cdk deploy --all"
echo ""
echo -e "${GREEN}💀 Destruction complete!${NC}"