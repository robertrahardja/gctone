#!/bin/bash

# SSO Permission Assignment Script
# ================================
# This script automates the assignment of existing IAM Identity Center users 
# to permission sets in workload accounts. It performs the exact steps that 
# would be done manually in the IAM Identity Center console.

# Exit on any error
set -e

# Load environment variables containing account IDs
source .env

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 SSO Permission Assignment Automation${NC}"
echo "========================================"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    # Check if we can access AWS
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo -e "${RED}❌ AWS CLI is not configured or no valid credentials${NC}"
        echo "Please ensure you're logged in with management account access"
        exit 1
    fi
    
    # Check jq for JSON processing
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is not installed (required for JSON processing)${NC}"
        echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to get IAM Identity Center instance information
get_identity_center_info() {
    echo -e "${YELLOW}🔍 Getting IAM Identity Center instance information...${NC}"
    
    # Get the Identity Center instance (use ap-southeast-1 for Singapore)
    local instance_info=$(aws sso-admin list-instances --region ap-southeast-1 --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to get IAM Identity Center instances${NC}"
        echo "Please ensure IAM Identity Center is enabled and your credentials have access"
        exit 1
    fi
    
    local instance_count=$(echo "$instance_info" | jq '.Instances | length')
    if [ "$instance_count" -eq 0 ]; then
        echo -e "${RED}❌ No IAM Identity Center instance found${NC}"
        echo "Please enable IAM Identity Center in the AWS Console first"
        exit 1
    fi
    
    # Extract instance ARN and Identity Store ID
    INSTANCE_ARN=$(echo "$instance_info" | jq -r '.Instances[0].InstanceArn')
    IDENTITY_STORE_ID=$(echo "$instance_info" | jq -r '.Instances[0].IdentityStoreId')
    
    echo -e "${GREEN}✅ Found IAM Identity Center instance${NC}"
    echo "  Instance ARN: $INSTANCE_ARN"
    echo "  Identity Store ID: $IDENTITY_STORE_ID"
    echo ""
    
    # Export for use in other functions
    export INSTANCE_ARN IDENTITY_STORE_ID
}

# Function to find or create AdminAccess permission set
ensure_admin_permission_set() {
    echo -e "${YELLOW}🔑 Ensuring AdminAccess permission set exists...${NC}"
    
    # Check if permission set already exists
    local existing_ps=$(aws sso-admin list-permission-sets \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to list permission sets${NC}"
        exit 1
    fi
    
    # Look for existing AdminAccess permission set
    local admin_ps_arn=""
    for ps_arn in $(echo "$existing_ps" | jq -r '.PermissionSets[]'); do
        local ps_details=$(aws sso-admin describe-permission-set \
            --region ap-southeast-1 \
            --instance-arn "$INSTANCE_ARN" \
            --permission-set-arn "$ps_arn" \
            --output json 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            local ps_name=$(echo "$ps_details" | jq -r '.PermissionSet.Name')
            if [ "$ps_name" = "AdminAccess" ]; then
                admin_ps_arn="$ps_arn"
                break
            fi
        fi
    done
    
    if [ -n "$admin_ps_arn" ]; then
        echo -e "${YELLOW}⏭️  AdminAccess permission set already exists${NC}"
        echo "  ARN: $admin_ps_arn"
        ADMIN_PERMISSION_SET_ARN="$admin_ps_arn"
    else
        echo -e "${YELLOW}📝 Creating AdminAccess permission set...${NC}"
        
        # Create new permission set
        local ps_result=$(aws sso-admin create-permission-set \
            --region ap-southeast-1 \
            --instance-arn "$INSTANCE_ARN" \
            --name "AdminAccess" \
            --description "Administrative access for all environments" \
            --session-duration "PT12H" \
            --output json 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to create AdminAccess permission set${NC}"
            exit 1
        fi
        
        ADMIN_PERMISSION_SET_ARN=$(echo "$ps_result" | jq -r '.PermissionSet.PermissionSetArn')
        echo -e "${GREEN}✅ Created AdminAccess permission set${NC}"
        echo "  ARN: $ADMIN_PERMISSION_SET_ARN"
        
        # Attach AWS managed AdministratorAccess policy
        echo -e "${YELLOW}📎 Attaching AdministratorAccess policy...${NC}"
        aws sso-admin attach-managed-policy-to-permission-set \
            --region ap-southeast-1 \
            --instance-arn "$INSTANCE_ARN" \
            --permission-set-arn "$ADMIN_PERMISSION_SET_ARN" \
            --managed-policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" \
            > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Attached AdministratorAccess policy${NC}"
        else
            echo -e "${YELLOW}⚠️  Policy attachment may have failed, but continuing...${NC}"
        fi
    fi
    
    export ADMIN_PERMISSION_SET_ARN
}

# Function to find user by email
find_user_by_email() {
    local email="$1"
    
    echo -e "${YELLOW}🔍 Finding user: $email${NC}"
    
    # List users and find by email
    local users=$(aws identitystore list-users \
        --region ap-southeast-1 \
        --identity-store-id "$IDENTITY_STORE_ID" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to list users${NC}"
        return 1
    fi
    
    # Find user with matching email
    local user_id=$(echo "$users" | jq -r --arg email "$email" \
        '.Users[] | select(.Emails[]?.Value == $email) | .UserId')
    
    if [ -z "$user_id" ] || [ "$user_id" = "null" ]; then
        echo -e "${RED}❌ User not found: $email${NC}"
        echo "  💡 Please create this user in IAM Identity Center first"
        return 1
    fi
    
    echo -e "${GREEN}✅ Found user: $user_id${NC}"
    echo "$user_id"
}

# Function to assign user to account with permission set
assign_user_to_account() {
    local user_id="$1"
    local account_id="$2"
    local environment="$3"
    local user_email="$4"
    
    echo -e "${YELLOW}🎯 Assigning $user_email to $environment account${NC}"
    echo "  Account: $account_id"
    echo "  Permission Set: AdminAccess"
    
    # Check if assignment already exists
    local existing_assignments=$(aws sso-admin list-account-assignments \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --account-id "$account_id" \
        --permission-set-arn "$ADMIN_PERMISSION_SET_ARN" \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local existing_user=$(echo "$existing_assignments" | jq -r --arg user_id "$user_id" \
            '.AccountAssignments[] | select(.PrincipalId == $user_id) | .PrincipalId')
        
        if [ -n "$existing_user" ] && [ "$existing_user" != "null" ]; then
            echo -e "${YELLOW}⏭️  Assignment already exists for $environment${NC}"
            return 0
        fi
    fi
    
    # Create new assignment
    echo -e "${YELLOW}📝 Creating account assignment...${NC}"
    local assignment_result=$(aws sso-admin create-account-assignment \
        --region ap-southeast-1 \
        --instance-arn "$INSTANCE_ARN" \
        --target-id "$account_id" \
        --target-type "AWS_ACCOUNT" \
        --permission-set-arn "$ADMIN_PERMISSION_SET_ARN" \
        --principal-type "USER" \
        --principal-id "$user_id" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create account assignment for $environment${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Created account assignment for $environment${NC}"
    
    # Wait for assignment to be ready
    echo -e "${YELLOW}⏳ Waiting for assignment to be provisioned...${NC}"
    local request_id=$(echo "$assignment_result" | jq -r '.AccountAssignmentCreationStatus.RequestId')
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local status_result=$(aws sso-admin describe-account-assignment-creation-status \
            --region ap-southeast-1 \
            --instance-arn "$INSTANCE_ARN" \
            --account-assignment-creation-request-id "$request_id" \
            --output json 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            local status=$(echo "$status_result" | jq -r '.AccountAssignmentCreationStatus.Status')
            
            case "$status" in
                "SUCCEEDED")
                    echo -e "${GREEN}✅ Assignment provisioned successfully${NC}"
                    return 0
                    ;;
                "FAILED")
                    echo -e "${RED}❌ Assignment provisioning failed${NC}"
                    local failure_reason=$(echo "$status_result" | jq -r '.AccountAssignmentCreationStatus.FailureReason // "Unknown"')
                    echo "  Reason: $failure_reason"
                    return 1
                    ;;
                "IN_PROGRESS")
                    echo -e "${YELLOW}⏳ Still provisioning... ($((attempt + 1))/$max_attempts)${NC}"
                    ;;
                *)
                    echo -e "${YELLOW}⏳ Status: $status ($((attempt + 1))/$max_attempts)${NC}"
                    ;;
            esac
        else
            echo -e "${YELLOW}⏳ Checking status... ($((attempt + 1))/$max_attempts)${NC}"
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Timeout waiting for assignment provisioning${NC}"
    return 1
}

# Main execution function
main() {
    echo "This script will assign existing IAM Identity Center users to AdminAccess"
    echo "permission sets in all workload accounts."
    echo ""
    
    # Check for base email parameter
    if [ -z "$BASE_EMAIL" ]; then
        echo -e "${YELLOW}⚠️  BASE_EMAIL environment variable not set${NC}"
        echo "This script expects users with emails like: user+dev@domain.com"
        echo ""
        echo "Usage examples:"
        echo "  BASE_EMAIL=testawsrahardja@gmail.com $0"
        echo ""
        read -p "Enter your base email address: " BASE_EMAIL
        if [ -z "$BASE_EMAIL" ]; then
            echo "No email provided, exiting"
            exit 1
        fi
    fi
    
    check_prerequisites
    get_identity_center_info
    ensure_admin_permission_set
    
    # Verify we have account IDs
    if [ -z "$dev_account_id" ] || [ -z "$staging_account_id" ] || [ -z "$shared_account_id" ] || [ -z "$prod_account_id" ]; then
        echo -e "${RED}❌ Missing account IDs in .env file${NC}"
        echo "Please run ./scripts/get-account-ids.sh first"
        exit 1
    fi
    
    echo -e "${BLUE}🚀 Starting permission assignment for all environments${NC}"
    echo ""
    
    # Generate email addresses
    local local_part=$(echo "$BASE_EMAIL" | cut -d'@' -f1)
    local domain=$(echo "$BASE_EMAIL" | cut -d'@' -f2)
    
    # Define environments and their details
    local environments="dev staging shared prod"
    local account_ids="$dev_account_id $staging_account_id $shared_account_id $prod_account_id"
    local env_names="Development Staging SharedServices Production"
    
    # Convert to arrays for easier handling
    set -- $environments; ENV_ARRAY=("$@")
    set -- $account_ids; ACCOUNT_ARRAY=("$@")
    set -- $env_names; NAME_ARRAY=("$@")
    
    local success_count=0
    local total_count=${#ENV_ARRAY[@]}
    
    # Process each environment
    for i in $(seq 0 $((total_count - 1))); do
        local env="${ENV_ARRAY[$i]}"
        local account_id="${ACCOUNT_ARRAY[$i]}"
        local env_name="${NAME_ARRAY[$i]}"
        local user_email="${local_part}+${env}@${domain}"
        
        echo -e "${BLUE}🏗️  Processing $env_name environment${NC}"
        echo "Account ID: $account_id"
        echo "User Email: $user_email"
        echo ""
        
        # Find user
        local user_id=$(find_user_by_email "$user_email")
        if [ $? -ne 0 ] || [ -z "$user_id" ]; then
            echo -e "${RED}❌ Skipping $env_name - user not found${NC}"
            echo ""
            continue
        fi
        
        # Assign user to account
        if assign_user_to_account "$user_id" "$account_id" "$env_name" "$user_email"; then
            success_count=$((success_count + 1))
            echo -e "${GREEN}✅ $env_name assignment completed${NC}"
        else
            echo -e "${RED}❌ $env_name assignment failed${NC}"
        fi
        echo ""
    done
    
    echo -e "${BLUE}📊 Assignment Summary${NC}"
    echo "===================="
    echo -e "Environments processed: ${GREEN}$total_count${NC}"
    echo -e "Successful assignments: ${GREEN}$success_count${NC}"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 All permission assignments completed successfully!${NC}"
        echo ""
        echo -e "${BLUE}🧪 Test your SSO profiles:${NC}"
        echo "aws sts get-caller-identity --profile tar-dev"
        echo "aws sts get-caller-identity --profile tar-staging"
        echo "aws sts get-caller-identity --profile tar-shared"
        echo "aws sts get-caller-identity --profile tar-prod"
    else
        echo -e "${YELLOW}⚠️  Some assignments failed${NC}"
        echo "Please check the errors above and retry if needed"
    fi
    
    echo ""
    echo -e "${BLUE}🚀 Next steps:${NC}"
    echo "1. Test SSO profiles (commands above)"
    echo "2. Run CDK bootstrap: ./scripts/bootstrap-accounts.sh"
    echo "3. Deploy applications: ./scripts/deploy-applications.sh"
}

# Run main function
main "$@"