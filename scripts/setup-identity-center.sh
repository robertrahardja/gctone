#!/bin/bash

# IAM Identity Center Setup Automation Script
# ==========================================
# This script automates the setup of IAM Identity Center (SSO) for 
# AWS Control Tower multi-account environments. It creates users,
# permission sets, and account assignments programmatically.

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

echo -e "${BLUE}🔧 IAM Identity Center Setup Automation${NC}"
echo "========================================="
echo ""

# Function to check if AWS CLI is properly configured
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
        echo "Please run: aws configure sso --profile your-profile"
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
    
    # Get the Identity Center instance
    local instance_info=$(aws sso-admin list-instances --output json 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$instance_info" ]; then
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
    
    if [ -z "$INSTANCE_ARN" ] || [ "$INSTANCE_ARN" = "null" ]; then
        echo -e "${RED}❌ Could not extract Instance ARN${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Found IAM Identity Center instance${NC}"
    echo "  Instance ARN: $INSTANCE_ARN"
    echo "  Identity Store ID: $IDENTITY_STORE_ID"
    echo ""
    
    # Export for use in other functions
    export INSTANCE_ARN IDENTITY_STORE_ID
}

# Function to create or get permission set
create_permission_set() {
    local env_name="$1"
    local policy_document="$2"
    local permission_set_name="${env_name}AdminAccess"
    
    echo -e "${YELLOW}🔑 Creating permission set: $permission_set_name${NC}"
    
    # Check if permission set already exists
    local existing_ps=$(aws sso-admin list-permission-sets \
        --instance-arn "$INSTANCE_ARN" \
        --output json 2>/dev/null | \
        jq -r --arg name "$permission_set_name" \
        '.PermissionSets[] as $arn | if ($arn | test($name)) then $arn else empty end')
    
    if [ -n "$existing_ps" ]; then
        echo -e "${YELLOW}⏭️  Permission set $permission_set_name already exists${NC}"
        echo "$existing_ps"
        return 0
    fi
    
    # Create new permission set
    local ps_result=$(aws sso-admin create-permission-set \
        --instance-arn "$INSTANCE_ARN" \
        --name "$permission_set_name" \
        --description "Administrative access for $env_name environment" \
        --session-duration "PT12H" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create permission set $permission_set_name${NC}"
        return 1
    fi
    
    local permission_set_arn=$(echo "$ps_result" | jq -r '.PermissionSet.PermissionSetArn')
    echo -e "${GREEN}✅ Created permission set: $permission_set_arn${NC}"
    
    # Attach inline policy
    if [ -n "$policy_document" ]; then
        aws sso-admin put-inline-policy-to-permission-set \
            --instance-arn "$INSTANCE_ARN" \
            --permission-set-arn "$permission_set_arn" \
            --inline-policy "$policy_document" \
            > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Attached inline policy to $permission_set_name${NC}"
        fi
    fi
    
    echo "$permission_set_arn"
}

# Function to create environment-specific IAM policies
create_environment_policy() {
    local environment="$1"
    
    local base_policy='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:*",
                    "lambda:*",
                    "apigateway:*",
                    "cloudformation:*",
                    "iam:*",
                    "s3:*",
                    "logs:*",
                    "cloudwatch:*",
                    "ssm:GetParameter*",
                    "ssm:PutParameter",
                    "ecr:*",
                    "ce:*",
                    "budgets:View*",
                    "account:GetAccountInformation"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRole",
                "Resource": "arn:aws:iam::*:role/OrganizationAccountAccessRole"
            }
        ]
    }'
    
    # Add production restrictions
    if [ "$environment" = "prod" ]; then
        local prod_policy=$(echo "$base_policy" | jq '.Statement += [
            {
                "Effect": "Deny",
                "Action": [
                    "iam:DeleteRole",
                    "iam:DeletePolicy",
                    "ec2:TerminateInstances"
                ],
                "Resource": "*",
                "Condition": {
                    "StringNotEquals": {
                        "aws:RequestedRegion": ["ap-southeast-1", "us-east-1"]
                    }
                }
            }
        ]')
        echo "$prod_policy"
    else
        echo "$base_policy"
    fi
}

# Function to create IAM Identity Center user
create_user() {
    local environment="$1"
    local account_id="$2"
    local base_email="$3"
    
    # Generate email address
    local user_email
    if [[ "$base_email" == *"@"* ]]; then
        # Use plus-addressing: user@domain.com -> user+env@domain.com
        local local_part=$(echo "$base_email" | cut -d'@' -f1)
        local domain=$(echo "$base_email" | cut -d'@' -f2)
        user_email="${local_part}+${environment}@${domain}"
    else
        # Use subdomain: domain.com -> env@domain.com
        user_email="${environment}@${base_email}"
    fi
    
    local username="${environment}-admin"
    local display_name="$(echo ${environment^}) Administrator"
    
    echo -e "${YELLOW}👤 Creating user: $username ($user_email)${NC}"
    
    # Check if user already exists
    local existing_user=$(aws identitystore list-users \
        --identity-store-id "$IDENTITY_STORE_ID" \
        --output json 2>/dev/null | \
        jq -r --arg email "$user_email" \
        '.Users[] | select(.Emails[]?.Value == $email) | .UserId')
    
    if [ -n "$existing_user" ]; then
        echo -e "${YELLOW}⏭️  User $user_email already exists${NC}"
        echo "$existing_user"
        return 0
    fi
    
    # Create new user
    local user_result=$(aws identitystore create-user \
        --identity-store-id "$IDENTITY_STORE_ID" \
        --user-name "$username" \
        --display-name "$display_name" \
        --name '{"GivenName":"'${display_name%% *}'","FamilyName":"'${display_name##* }'"}' \
        --emails '[{"Value":"'$user_email'","Type":"work","Primary":true}]' \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create user $username${NC}"
        return 1
    fi
    
    local user_id=$(echo "$user_result" | jq -r '.UserId')
    echo -e "${GREEN}✅ Created user: $user_id${NC}"
    
    echo "$user_id"
}

# Function to create account assignment
create_account_assignment() {
    local user_id="$1"
    local permission_set_arn="$2"
    local account_id="$3"
    local environment="$4"
    
    echo -e "${YELLOW}🎯 Creating account assignment for $environment environment${NC}"
    
    # Check if assignment already exists
    local existing_assignment=$(aws sso-admin list-account-assignments \
        --instance-arn "$INSTANCE_ARN" \
        --account-id "$account_id" \
        --permission-set-arn "$permission_set_arn" \
        --output json 2>/dev/null | \
        jq -r --arg user_id "$user_id" \
        '.AccountAssignments[] | select(.PrincipalId == $user_id) | .PrincipalId')
    
    if [ -n "$existing_assignment" ]; then
        echo -e "${YELLOW}⏭️  Account assignment already exists for $environment${NC}"
        return 0
    fi
    
    # Create new assignment
    local assignment_result=$(aws sso-admin create-account-assignment \
        --instance-arn "$INSTANCE_ARN" \
        --target-id "$account_id" \
        --target-type "AWS_ACCOUNT" \
        --permission-set-arn "$permission_set_arn" \
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
    
    while true; do
        local status=$(aws sso-admin describe-account-assignment-creation-status \
            --instance-arn "$INSTANCE_ARN" \
            --account-assignment-creation-request-id "$request_id" \
            --output json 2>/dev/null | \
            jq -r '.AccountAssignmentCreationStatus.Status')
        
        case "$status" in
            "SUCCEEDED")
                echo -e "${GREEN}✅ Account assignment provisioned successfully${NC}"
                break
                ;;
            "FAILED")
                echo -e "${RED}❌ Account assignment provisioning failed${NC}"
                return 1
                ;;
            "IN_PROGRESS")
                echo -e "${YELLOW}⏳ Still provisioning...${NC}"
                sleep 10
                ;;
            *)
                echo -e "${YELLOW}⏳ Unknown status: $status${NC}"
                sleep 5
                ;;
        esac
    done
}

# Main setup function
setup_environment() {
    local environment="$1"
    local account_id="$2"
    local env_display_name="$3"
    
    echo -e "${BLUE}🏗️  Setting up $env_display_name environment${NC}"
    echo "Account ID: $account_id"
    echo ""
    
    # Create environment-specific policy
    local policy_document=$(create_environment_policy "$environment")
    
    # Create permission set
    local permission_set_arn=$(create_permission_set "$environment" "$policy_document")
    
    if [ -z "$permission_set_arn" ]; then
        echo -e "${RED}❌ Failed to create permission set for $environment${NC}"
        return 1
    fi
    
    # Create user (if BASE_EMAIL is provided)
    if [ -n "$BASE_EMAIL" ]; then
        local user_id=$(create_user "$environment" "$account_id" "$BASE_EMAIL")
        
        if [ -z "$user_id" ]; then
            echo -e "${RED}❌ Failed to create user for $environment${NC}"
            return 1
        fi
        
        # Create account assignment
        create_account_assignment "$user_id" "$permission_set_arn" "$account_id" "$environment"
    else
        echo -e "${YELLOW}⚠️  BASE_EMAIL not provided, skipping user creation${NC}"
        echo "  💡 Set BASE_EMAIL environment variable to create users automatically"
    fi
    
    echo ""
}

# Main execution
main() {
    echo "This script will set up IAM Identity Center for your Control Tower environment"
    echo ""
    
    # Check for base email parameter
    if [ -z "$BASE_EMAIL" ]; then
        echo -e "${YELLOW}⚠️  BASE_EMAIL environment variable not set${NC}"
        echo "Usage examples:"
        echo "  BASE_EMAIL=user@company.com $0    # Creates user+dev@company.com, etc."
        echo "  BASE_EMAIL=company.com $0          # Creates dev@company.com, etc."
        echo ""
        read -p "Continue without creating users? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    check_prerequisites
    get_identity_center_info
    
    # Verify we have account IDs
    if [ -z "$dev_account_id" ] || [ -z "$staging_account_id" ] || [ -z "$shared_account_id" ] || [ -z "$prod_account_id" ]; then
        echo -e "${RED}❌ Missing account IDs in .env file${NC}"
        echo "Please run ./scripts/get-account-ids.sh first"
        exit 1
    fi
    
    echo -e "${BLUE}🚀 Starting IAM Identity Center setup for all environments${NC}"
    echo ""
    
    # Set up each environment
    setup_environment "dev" "$dev_account_id" "Development"
    setup_environment "staging" "$staging_account_id" "Staging"
    setup_environment "shared" "$shared_account_id" "Shared Services"
    setup_environment "prod" "$prod_account_id" "Production"
    
    echo -e "${GREEN}🎉 IAM Identity Center setup completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Run SSO profile setup: ./scripts/setup-automated-sso.sh"
    echo "2. Bootstrap CDK: ./scripts/bootstrap-accounts.sh"
    echo "3. Deploy applications: ./scripts/deploy-applications.sh"
    echo ""
    
    # Generate summary
    cat > identity-center-summary.md << EOF
# IAM Identity Center Setup Summary

Generated on: $(date)

## Instance Information
- Instance ARN: \`$INSTANCE_ARN\`
- Identity Store ID: \`$IDENTITY_STORE_ID\`

## Created Resources

### Permission Sets
| Environment | Permission Set | Account ID |
|-------------|----------------|------------|
| Development | DevAdminAccess | $dev_account_id |
| Staging | StagingAdminAccess | $staging_account_id |
| Shared Services | SharedAdminAccess | $shared_account_id |
| Production | ProdAdminAccess | $prod_account_id |

### Users (if BASE_EMAIL provided)
$(if [ -n "$BASE_EMAIL" ]; then
cat << USERS
| Environment | Email | Username |
|-------------|-------|----------|
| Development | $(echo "$BASE_EMAIL" | sed 's/@/+dev@/' | sed 's/^/dev@/' | head -1) | dev-admin |
| Staging | $(echo "$BASE_EMAIL" | sed 's/@/+staging@/' | sed 's/^/staging@/' | head -1) | staging-admin |
| Shared Services | $(echo "$BASE_EMAIL" | sed 's/@/+shared@/' | sed 's/^/shared@/' | head -1) | shared-admin |
| Production | $(echo "$BASE_EMAIL" | sed 's/@/+prod@/' | sed 's/^/prod@/' | head -1) | prod-admin |
USERS
else
echo "No users created (BASE_EMAIL not provided)"
fi)

## Next Steps
1. \`./scripts/setup-automated-sso.sh\` - Create AWS CLI profiles
2. \`./scripts/bootstrap-accounts.sh\` - Bootstrap CDK
3. \`./scripts/deploy-applications.sh\` - Deploy applications

## Manual Steps (if needed)
- Access IAM Identity Center console to verify setup
- Assign additional users to permission sets as needed
- Configure MFA requirements in Identity Center settings
EOF
    
    echo -e "${GREEN}📄 Summary saved to: identity-center-summary.md${NC}"
}

# Run main function
main "$@"