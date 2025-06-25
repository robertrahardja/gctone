#!/bin/bash

# Fast SSO Permission Assignment Script
# ====================================
# Creates all assignments without waiting for provisioning
# AWS will process them in the background

set -e
source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Fast SSO Permission Assignment${NC}"
echo "=================================="
echo ""

# Check prerequisites
if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ AWS CLI or jq not installed${NC}"
    exit 1
fi

if [ -z "$BASE_EMAIL" ]; then
    BASE_EMAIL="testawsrahardja@gmail.com"
fi

echo -e "${YELLOW}📧 Base Email: $BASE_EMAIL${NC}"

# Get Identity Center info
echo -e "${YELLOW}🔍 Getting IAM Identity Center info...${NC}"
INSTANCE_INFO=$(aws sso-admin list-instances --region ap-southeast-1 --output json 2>/dev/null)
INSTANCE_ARN=$(echo "$INSTANCE_INFO" | jq -r '.Instances[0].InstanceArn')
IDENTITY_STORE_ID=$(echo "$INSTANCE_INFO" | jq -r '.Instances[0].IdentityStoreId')

echo -e "${GREEN}✅ Instance ARN: $INSTANCE_ARN${NC}"
echo -e "${GREEN}✅ Identity Store: $IDENTITY_STORE_ID${NC}"

# Get AdminAccess permission set
echo -e "${YELLOW}🔑 Getting AdminAccess permission set...${NC}"
PERMISSION_SETS=$(aws sso-admin list-permission-sets --region ap-southeast-1 --instance-arn "$INSTANCE_ARN" --output json)
ADMIN_PS_ARN=""

for ps_arn in $(echo "$PERMISSION_SETS" | jq -r '.PermissionSets[]'); do
    PS_DETAILS=$(aws sso-admin describe-permission-set --region ap-southeast-1 --instance-arn "$INSTANCE_ARN" --permission-set-arn "$ps_arn" --output json 2>/dev/null)
    PS_NAME=$(echo "$PS_DETAILS" | jq -r '.PermissionSet.Name')
    if [ "$PS_NAME" = "AdminAccess" ]; then
        ADMIN_PS_ARN="$ps_arn"
        break
    fi
done

if [ -z "$ADMIN_PS_ARN" ]; then
    echo -e "${RED}❌ AdminAccess permission set not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found AdminAccess: $ADMIN_PS_ARN${NC}"

# Find users
echo -e "${YELLOW}👥 Finding users...${NC}"
USERS=$(aws identitystore list-users --region ap-southeast-1 --identity-store-id "$IDENTITY_STORE_ID" --output json)

local_part=$(echo "$BASE_EMAIL" | cut -d'@' -f1)
domain=$(echo "$BASE_EMAIL" | cut -d'@' -f2)

# Create assignments for all environments
ENVIRONMENTS=("dev:$dev_account_id" "staging:$staging_account_id" "shared:$shared_account_id" "prod:$prod_account_id")

for env_info in "${ENVIRONMENTS[@]}"; do
    IFS=':' read -r env account_id <<< "$env_info"
    user_email="${local_part}+${env}@${domain}"
    
    echo -e "${BLUE}🏗️  Processing $env environment${NC}"
    echo "Account: $account_id"
    echo "Email: $user_email"
    
    # Find user ID
    USER_ID=$(echo "$USERS" | jq -r --arg email "$user_email" '.Users[] | select(.Emails[]?.Value == $email) | .UserId')
    
    if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
        echo -e "${RED}❌ User not found: $user_email${NC}"
        continue
    fi
    
    echo -e "${GREEN}✅ Found user: $USER_ID${NC}"
    
    # Check if assignment exists
    EXISTING=$(aws sso-admin list-account-assignments \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --account-id "$account_id" \
        --permission-set-arn "$ADMIN_PS_ARN" \
        --output json 2>/dev/null | \
        jq -r --arg user_id "$USER_ID" '.AccountAssignments[] | select(.PrincipalId == $user_id) | .PrincipalId')
    
    if [ -n "$EXISTING" ] && [ "$EXISTING" != "null" ]; then
        echo -e "${YELLOW}⏭️  Assignment already exists for $env${NC}"
        continue
    fi
    
    # Create assignment (don't wait for provisioning)
    echo -e "${YELLOW}📝 Creating assignment for $env...${NC}"
    RESULT=$(aws sso-admin create-account-assignment \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --target-id "$account_id" \
        --target-type "AWS_ACCOUNT" \
        --permission-set-arn "$ADMIN_PS_ARN" \
        --principal-type "USER" \
        --principal-id "$USER_ID" \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        REQUEST_ID=$(echo "$RESULT" | jq -r '.AccountAssignmentCreationStatus.RequestId')
        echo -e "${GREEN}✅ Assignment created for $env (Request: $REQUEST_ID)${NC}"
    else
        echo -e "${RED}❌ Failed to create assignment for $env${NC}"
    fi
    
    echo ""
done

echo -e "${GREEN}🎉 All assignments submitted!${NC}"
echo ""
echo -e "${YELLOW}⏳ AWS is processing assignments in the background (2-3 minutes each)${NC}"
echo ""
echo -e "${BLUE}🧪 Test your profiles in a few minutes:${NC}"
echo "aws sts get-caller-identity --profile tar-dev"
echo "aws sts get-caller-identity --profile tar-staging"
echo "aws sts get-caller-identity --profile tar-shared"
echo "aws sts get-caller-identity --profile tar-prod"
echo ""
echo -e "${BLUE}💡 You can also check status in IAM Identity Center console:${NC}"
echo "https://console.aws.amazon.com/singlesignon"
echo ""
echo -e "${GREEN}🚀 Once profiles work, continue with:${NC}"
echo "./scripts/bootstrap-accounts.sh"