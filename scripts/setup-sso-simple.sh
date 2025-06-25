#!/bin/bash

# Simplified SSO Setup Script
# ===========================
# This script combines the essential SSO setup operations:
# 1. Creates SSO profiles for all accounts
# 2. Assigns current user to all accounts  
# 3. Waits for access to be ready
# 4. Validates everything works
#
# Usage: ./scripts/setup-sso-simple.sh [email@domain.com]

set -e
source .env 2>/dev/null || { echo "❌ Run ./scripts/get-account-ids.sh first"; exit 1; }

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get base email
BASE_EMAIL="${1:-$BASE_EMAIL}"
if [ -z "$BASE_EMAIL" ]; then
    echo -e "${YELLOW}📧 Enter your email address:${NC}"
    read -p "Email: " BASE_EMAIL
    if [ -z "$BASE_EMAIL" ]; then
        echo -e "${RED}❌ No email provided${NC}"
        exit 1
    fi
    echo "BASE_EMAIL=\"$BASE_EMAIL\"" >> .env
fi

echo -e "${BLUE}🔐 Simple SSO Setup${NC}"
echo "==================="
echo "Email: $BASE_EMAIL"
echo ""

# Step 1: Create SSO profiles
echo -e "${YELLOW}📝 Step 1: Creating SSO profiles...${NC}"
./scripts/setup-automated-sso.sh

# Step 2: Get current user and assign to all accounts
echo -e "${YELLOW}👤 Step 2: Assigning current user to all accounts...${NC}"

# Get Identity Center info
INSTANCE_INFO=$(aws sso-admin list-instances --region ap-southeast-1 --output json 2>/dev/null)
INSTANCE_ARN=$(echo "$INSTANCE_INFO" | jq -r '.Instances[0].InstanceArn')
IDENTITY_STORE_ID=$(echo "$INSTANCE_INFO" | jq -r '.Instances[0].IdentityStoreId')

# Get AdminAccess permission set
PERMISSION_SETS=$(aws sso-admin list-permission-sets --region ap-southeast-1 --instance-arn "$INSTANCE_ARN" --output json)
ADMIN_PS_ARN=""
for ps_arn in $(echo "$PERMISSION_SETS" | jq -r '.PermissionSets[]'); do
    PS_DETAILS=$(aws sso-admin describe-permission-set --region ap-southeast-1 --instance-arn "$INSTANCE_ARN" --permission-set-arn "$ps_arn" --output json 2>/dev/null)
    PS_NAME=$(echo "$PS_DETAILS" | jq -r '.PermissionSet.Name')
    if [ "$PS_NAME" = "AdminAccess" ] || [ "$PS_NAME" = "AWSAdministratorAccess" ]; then
        ADMIN_PS_ARN="$ps_arn"
        break
    fi
done

if [ -z "$ADMIN_PS_ARN" ]; then
    echo -e "${RED}❌ AdminAccess permission set not found${NC}"
    exit 1
fi

# Find current user
USERS=$(aws identitystore list-users --region ap-southeast-1 --identity-store-id "$IDENTITY_STORE_ID" --output json)
USER_ID=$(echo "$USERS" | jq -r --arg email "$BASE_EMAIL" '.Users[] | select(.Emails[]?.Value == $email) | .UserId')

if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    echo -e "${RED}❌ User not found: $BASE_EMAIL${NC}"
    echo "Please create this user in IAM Identity Center first"
    exit 1
fi

echo -e "${GREEN}✅ Found user: $USER_ID${NC}"

# Create assignments for all accounts
ACCOUNTS=("$dev_account_id:dev" "$staging_account_id:staging" "$shared_account_id:shared" "$prod_account_id:prod")

for account_info in "${ACCOUNTS[@]}"; do
    IFS=':' read -r account_id env <<< "$account_info"
    
    # Check if assignment exists
    EXISTING=$(aws sso-admin list-account-assignments \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --account-id "$account_id" \
        --permission-set-arn "$ADMIN_PS_ARN" \
        --output json 2>/dev/null | \
        jq -r --arg user_id "$USER_ID" '.AccountAssignments[] | select(.PrincipalId == $user_id) | .PrincipalId')
    
    if [ -n "$EXISTING" ] && [ "$EXISTING" != "null" ]; then
        echo -e "${GREEN}  ✅ $env assignment already exists${NC}"
    else
        echo -e "${YELLOW}  📝 Creating $env assignment...${NC}"
        aws sso-admin create-account-assignment \
            --region ap-southeast-1 \
            --instance-arn "$INSTANCE_ARN" \
            --target-id "$account_id" \
            --target-type "AWS_ACCOUNT" \
            --permission-set-arn "$ADMIN_PS_ARN" \
            --principal-type "USER" \
            --principal-id "$USER_ID" \
            --output json > /dev/null
        echo -e "${GREEN}  ✅ $env assignment created${NC}"
    fi
done

# Step 3: Wait for access
echo -e "${YELLOW}⏳ Step 3: Waiting for SSO access (30 seconds)...${NC}"
sleep 30

# Step 4: Test all profiles
echo -e "${YELLOW}🧪 Step 4: Testing all profiles...${NC}"
PROFILES=("tar-dev:dev" "tar-staging:staging" "tar-shared:shared" "tar-prod:prod")
SUCCESS_COUNT=0

for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile env <<< "$profile_info"
    
    if aws sts get-caller-identity --profile "$profile" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ $env ($profile) - Working${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${YELLOW}  ⏳ $env ($profile) - Still provisioning${NC}"
    fi
done

echo ""
if [ $SUCCESS_COUNT -eq 4 ]; then
    echo -e "${GREEN}🎉 SUCCESS! All SSO profiles are working!${NC}"
    echo ""
    echo -e "${BLUE}🧪 Test commands:${NC}"
    echo "aws sts get-caller-identity --profile tar-dev"
    echo "aws sts get-caller-identity --profile tar-staging" 
    echo "aws sts get-caller-identity --profile tar-shared"
    echo "aws sts get-caller-identity --profile tar-prod"
    echo ""
    echo -e "${BLUE}🚀 Ready for CDK bootstrap:${NC}"
    echo "./scripts/bootstrap-accounts.sh"
else
    echo -e "${YELLOW}⏳ Partially ready ($SUCCESS_COUNT/4 profiles working)${NC}"
    echo "AWS may still be provisioning. Wait 2-3 minutes and run:"
    echo "./scripts/check-sso-status.sh"
fi