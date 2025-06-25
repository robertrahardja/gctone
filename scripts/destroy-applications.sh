#!/bin/bash

# Application Destruction Script
# ==============================
# This script safely destroys all deployed applications while preserving
# the foundational infrastructure (Control Tower, CDK bootstrap, SSO profiles)
#
# What gets destroyed:
# - Lambda functions and API Gateways ($$$ savings)
# - CloudWatch Log Groups  
# - Application CloudFormation stacks
#
# What stays (FREE or minimal cost):
# - Control Tower accounts and governance
# - CDK bootstrap infrastructure
# - SSO profiles and Identity Center
# - S3 buckets (empty, minimal cost)
# - IAM roles and policies

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🗑️ Application Destruction Script${NC}"
echo "=================================="
echo ""
echo "This will destroy all deployed applications to save money."
echo "Foundation infrastructure (Control Tower, CDK bootstrap) will remain."
echo ""

# Confirm with user
echo -e "${YELLOW}⚠️ WARNING: This will destroy the following:${NC}"
echo "• All Lambda functions (saves ~$5-15/month per function)"
echo "• All API Gateways (saves ~$3-10/month per API)" 
echo "• CloudWatch Log Groups (saves ~$1-5/month)"
echo "• Application stacks in all 4 environments"
echo ""
echo -e "${GREEN}✅ PRESERVED (no additional cost):${NC}"
echo "• Control Tower accounts and governance"
echo "• CDK bootstrap infrastructure" 
echo "• SSO profiles and access"
echo "• S3 buckets (empty, ~$0.02/month)"
echo ""

read -p "Are you sure you want to proceed? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo -e "${PURPLE}🚀 Starting application destruction...${NC}"

# Check prerequisites
if ! command -v aws &> /dev/null || ! command -v cdk &> /dev/null; then
    echo -e "${RED}❌ AWS CLI or CDK not found${NC}"
    exit 1
fi

# Load environment
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Run ./scripts/get-account-ids.sh first${NC}"
    exit 1
fi

source .env

# Define stacks and profiles
STACKS=("helloworld-dev:tar-dev" "helloworld-staging:tar-staging" "helloworld-shared:tar-shared" "helloworld-prod:tar-prod")

SUCCESS_COUNT=0
TOTAL_COUNT=${#STACKS[@]}

# Destroy each stack
for stack_info in "${STACKS[@]}"; do
    IFS=':' read -r stack_name profile <<< "$stack_info"
    
    echo -e "${YELLOW}🗑️ Destroying $stack_name...${NC}"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$stack_name" --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
        echo "  Stack exists, proceeding with destruction..."
        
        # Destroy the stack
        if AWS_PROFILE="$profile" cdk destroy "$stack_name" --force; then
            echo -e "${GREEN}  ✅ $stack_name destroyed successfully${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "${RED}  ❌ Failed to destroy $stack_name${NC}"
        fi
    else
        echo -e "${YELLOW}  ⏭️ $stack_name doesn't exist, skipping${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}📊 Destruction Summary${NC}"
echo "======================"
echo -e "Stacks processed: ${SUCCESS_COUNT}/${TOTAL_COUNT}"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}🎉 All applications destroyed successfully!${NC}"
    echo ""
    echo -e "${BLUE}💰 Monthly cost savings:${NC}"
    echo "• Lambda functions: ~$20-60/month saved"
    echo "• API Gateways: ~$12-40/month saved"  
    echo "• CloudWatch logs: ~$4-20/month saved"
    echo "• Total savings: ~$36-120/month"
    echo ""
    echo -e "${BLUE}💡 What remains (minimal cost):${NC}"
    echo "• Control Tower accounts: ~$0/month (free)"
    echo "• CDK bootstrap S3 buckets: ~$0.10/month total"
    echo "• IAM resources: ~$0/month (free)"
    echo "• Total remaining cost: ~$0.10/month"
    echo ""
    echo -e "${GREEN}✅ Your infrastructure foundation is preserved and ready for future deployments!${NC}"
    echo ""
    echo -e "${BLUE}🚀 To redeploy later:${NC}"
    echo "• npm run build"
    echo "• cdk deploy --all"
    echo "• OR: ./scripts/deploy-applications.sh"
elif [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Partial success. Some stacks may need manual cleanup.${NC}"
else
    echo -e "${RED}❌ No stacks were destroyed. Check errors above.${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Verify destruction with:${NC}"
echo "aws cloudformation list-stacks --profile tar-dev --region ap-southeast-1 --stack-status-filter DELETE_COMPLETE"