#!/bin/bash

# Complete Setup Validation Script
# ================================
# This script validates that your entire Control Tower environment is properly set up:
# • Account discovery (.env file)
# • SSO profiles and access
# • CDK bootstrap status
# • Ready for deployments
#
# Usage: ./scripts/validate-complete-setup.sh [--verbose]

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

VERBOSE=false
if [ "$1" = "--verbose" ]; then
    VERBOSE=true
fi

echo -e "${BLUE}🔍 Complete Environment Validation${NC}"
echo "=================================="
echo ""

# Track overall status
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Helper function to run a check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local success_message="$3"
    local failure_message="$4"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}🔍 Checking: $check_name${NC}"
    fi
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $success_message${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}❌ $failure_message${NC}"
        return 1
    fi
}

# Check 1: Prerequisites
echo -e "${PURPLE}📋 Prerequisites${NC}"
run_check "AWS CLI" "command -v aws" "AWS CLI installed" "AWS CLI not installed"
run_check "jq" "command -v jq" "jq installed" "jq not installed"
run_check "CDK CLI" "command -v cdk" "CDK CLI installed" "CDK CLI not installed"
run_check "AWS credentials" "aws sts get-caller-identity" "AWS credentials valid" "AWS credentials invalid"
echo ""

# Check 2: Account Discovery
echo -e "${PURPLE}📋 Account Discovery${NC}"
if run_check "Environment file" "[ -f .env ]" ".env file exists" ".env file missing"; then
    source .env
    run_check "Dev account ID" "[ -n \"$dev_account_id\" ]" "Development account ID found" "Development account ID missing"
    run_check "Staging account ID" "[ -n \"$staging_account_id\" ]" "Staging account ID found" "Staging account ID missing"
    run_check "Shared account ID" "[ -n \"$shared_account_id\" ]" "Shared Services account ID found" "Shared Services account ID missing"
    run_check "Prod account ID" "[ -n \"$prod_account_id\" ]" "Production account ID found" "Production account ID missing"
    run_check "Management account ID" "[ -n \"$management_account_id\" ]" "Management account ID found" "Management account ID missing"
    
    if [ "$VERBOSE" = true ]; then
        echo "  Dev: $dev_account_id"
        echo "  Staging: $staging_account_id"
        echo "  Shared: $shared_account_id"
        echo "  Prod: $prod_account_id"
        echo "  Management: $management_account_id"
    fi
fi
echo ""

# Check 3: SSO Profiles
echo -e "${PURPLE}📋 SSO Profiles${NC}"
PROFILES=("tar-dev:Development:$dev_account_id" "tar-staging:Staging:$staging_account_id" "tar-shared:Shared Services:$shared_account_id" "tar-prod:Production:$prod_account_id")

for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile name account_id <<< "$profile_info"
    
    if run_check "$name profile" "aws sts get-caller-identity --profile \"$profile\"" "$name profile working" "$name profile not working"; then
        if [ "$VERBOSE" = true ]; then
            ACCOUNT_INFO=$(aws sts get-caller-identity --profile "$profile" --output json 2>/dev/null)
            ACTUAL_ACCOUNT=$(echo "$ACCOUNT_INFO" | jq -r '.Account')
            USER_ARN=$(echo "$ACCOUNT_INFO" | jq -r '.Arn')
            echo "    Account: $ACTUAL_ACCOUNT"
            echo "    User: $USER_ARN"
        fi
    fi
done
echo ""

# Check 4: CDK Bootstrap
echo -e "${PURPLE}📋 CDK Bootstrap${NC}"
for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile name account_id <<< "$profile_info"
    
    if run_check "$name CDK" "aws cloudformation describe-stacks --stack-name cdktoolkit --profile \"$profile\" --region ap-southeast-1" "$name CDK toolkit ready" "$name CDK toolkit missing"; then
        if [ "$VERBOSE" = true ]; then
            STACK_STATUS=$(aws cloudformation describe-stacks --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
            echo "    Stack Status: $STACK_STATUS"
        fi
    fi
done
echo ""

# Check 5: IAM Identity Center
echo -e "${PURPLE}📋 IAM Identity Center${NC}"
run_check "Identity Center instance" "aws sso-admin list-instances --region ap-southeast-1" "IAM Identity Center available" "IAM Identity Center not accessible"

if [ $? -eq 0 ]; then
    INSTANCE_INFO=$(aws sso-admin list-instances --region ap-southeast-1 --output json 2>/dev/null)
    INSTANCE_ARN=$(echo "$INSTANCE_INFO" | jq -r '.Instances[0].InstanceArn')
    
    run_check "AdminAccess permission set" "aws sso-admin list-permission-sets --region ap-southeast-1 --instance-arn \"$INSTANCE_ARN\"" "Permission sets accessible" "Permission sets not accessible"
    
    if [ "$VERBOSE" = true ]; then
        echo "    Instance ARN: $INSTANCE_ARN"
    fi
fi
echo ""

# Final Summary
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "===================="
echo -e "Checks Passed: ${GREEN}$PASSED_CHECKS/$TOTAL_CHECKS${NC}"

PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 PERFECT! Your environment is 100% ready!${NC}"
    echo ""
    echo -e "${BLUE}🚀 You can now:${NC}"
    echo "• Deploy applications: ./scripts/deploy-applications.sh"
    echo "• Create budgets: ./scripts/create-budgets.sh"
    echo "• Set up monitoring: ./scripts/create-per-account-alerts.sh"
    echo ""
    echo -e "${BLUE}🧪 Quick Test Commands:${NC}"
    echo "aws sts get-caller-identity --profile tar-dev"
    echo "aws sts get-caller-identity --profile tar-staging"
    echo "cdk list --profile tar-dev"
    
    exit 0
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  Environment is $PERCENTAGE% ready (minor issues)${NC}"
    echo ""
    echo -e "${BLUE}💡 Likely fixes:${NC}"
    echo "• Re-run SSO setup: ./scripts/setup-sso-simple.sh"
    echo "• Re-run bootstrap: ./scripts/bootstrap-accounts.sh"
    
    exit 1
elif [ $PERCENTAGE -ge 50 ]; then
    echo -e "${YELLOW}⚠️  Environment is $PERCENTAGE% ready (moderate issues)${NC}"
    echo ""
    echo -e "${BLUE}💡 Recommended actions:${NC}"
    echo "• Complete setup: ./scripts/setup-complete-environment.sh"
    echo "• Check SSO status: ./scripts/check-sso-status.sh"
    
    exit 1
else
    echo -e "${RED}❌ Environment is only $PERCENTAGE% ready (major issues)${NC}"
    echo ""
    echo -e "${BLUE}💡 Start fresh:${NC}"
    echo "• Run complete setup: ./scripts/setup-complete-environment.sh"
    echo "• Check prerequisites and AWS access"
    
    exit 1
fi