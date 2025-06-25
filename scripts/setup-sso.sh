#!/bin/bash

# Configure IAM Identity Center (SSO) after Control Tower setup
# This automates the SSO configuration that was previously manual

set -e

echo "🔐 Setting up IAM Identity Center (SSO)"
echo "======================================"

# Get SSO instance ARN
SSO_INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)

if [ "$SSO_INSTANCE_ARN" = "None" ] || [ -z "$SSO_INSTANCE_ARN" ]; then
    echo "❌ IAM Identity Center not found. It should be enabled by Control Tower."
    echo "Please enable it manually in the AWS Console first."
    exit 1
fi

echo "✅ Found SSO Instance: $SSO_INSTANCE_ARN"

# Get Identity Store ID
IDENTITY_STORE_ID=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)
echo "✅ Identity Store ID: $IDENTITY_STORE_ID"

# Function to create permission set
create_permission_set() {
    local name="$1"
    local description="$2"
    local policy_arn="$3"
    local session_duration="$4"
    
    echo "Creating permission set: $name"
    
    # Create permission set
    PERMISSION_SET_ARN=$(aws sso-admin create-permission-set \
        --instance-arn $SSO_INSTANCE_ARN \
        --name "$name" \
        --description "$description" \
        --session-duration "$session_duration" \
        --query 'PermissionSet.PermissionSetArn' --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Created permission set: $name"
        
        # Attach managed policy
        aws sso-admin attach-managed-policy-to-permission-set \
            --instance-arn $SSO_INSTANCE_ARN \
            --permission-set-arn $PERMISSION_SET_ARN \
            --managed-policy-arn "$policy_arn"
            
        echo "✅ Attached policy $policy_arn to $name"
        
        # Provision permission set
        aws sso-admin provision-permission-set \
            --instance-arn $SSO_INSTANCE_ARN \
            --permission-set-arn $PERMISSION_SET_ARN \
            --target-type AWS_ACCOUNT \
            --target-id $(aws sts get-caller-identity --query Account --output text)
            
        echo "✅ Provisioned permission set: $name"
    else
        echo "⚠️  Permission set $name may already exist"
        # Try to get existing permission set ARN
        PERMISSION_SET_ARN=$(aws sso-admin list-permission-sets \
            --instance-arn $SSO_INSTANCE_ARN \
            --query "PermissionSets[?contains(@, '$name')]" --output text)
    fi
    
    echo "$PERMISSION_SET_ARN"
}

# Create permission sets
echo "📋 Creating permission sets..."

# Developer Access (PowerUser)
DEV_PS_ARN=$(create_permission_set \
    "DeveloperAccess" \
    "Developer access to non-production environments" \
    "arn:aws:iam::aws:policy/PowerUserAccess" \
    "PT8H")

# Admin Access (Full Admin)
ADMIN_PS_ARN=$(create_permission_set \
    "AdminAccess" \
    "Administrative access to all environments" \
    "arn:aws:iam::aws:policy/AdministratorAccess" \
    "PT4H")

# ReadOnly Access
READONLY_PS_ARN=$(create_permission_set \
    "ReadOnlyAccess" \
    "Read-only access for monitoring and auditing" \
    "arn:aws:iam::aws:policy/ReadOnlyAccess" \
    "PT12H")

echo "✅ All permission sets created"

# Function to create user
create_sso_user() {
    local username="$1"
    local email="$2"
    local first_name="$3"
    local last_name="$4"
    
    echo "Creating SSO user: $username"
    
    USER_ID=$(aws identitystore create-user \
        --identity-store-id $IDENTITY_STORE_ID \
        --user-name "$username" \
        --name "FamilyName=$last_name,GivenName=$first_name" \
        --emails "Value=$email,Type=work,Primary=true" \
        --query 'UserId' --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Created user: $username (ID: $USER_ID)"
    else
        echo "⚠️  User $username may already exist"
        # Try to get existing user ID
        USER_ID=$(aws identitystore list-users \
            --identity-store-id $IDENTITY_STORE_ID \
            --query "Users[?UserName=='$username'].UserId" --output text)
    fi
    
    echo "$USER_ID"
}

# Get user details
read -p "Enter your username for SSO (e.g., your-name): " SSO_USERNAME
read -p "Enter your email: " SSO_EMAIL
read -p "Enter your first name: " FIRST_NAME
read -p "Enter your last name: " LAST_NAME

if [ -z "$SSO_USERNAME" ] || [ -z "$SSO_EMAIL" ] || [ -z "$FIRST_NAME" ] || [ -z "$LAST_NAME" ]; then
    echo "❌ All user details are required"
    exit 1
fi

# Create SSO user
echo "👤 Creating SSO user..."
USER_ID=$(create_sso_user "$SSO_USERNAME" "$SSO_EMAIL" "$FIRST_NAME" "$LAST_NAME")

# Function to assign user to account with permission set
assign_user_to_account() {
    local account_id="$1"
    local account_name="$2"
    local permission_set_arn="$3"
    local permission_set_name="$4"
    
    if [ -z "$account_id" ] || [ "$account_id" = "None" ]; then
        echo "⚠️  Skipping $account_name - account ID not available"
        return
    fi
    
    echo "Assigning user to $account_name with $permission_set_name"
    
    aws sso-admin create-account-assignment \
        --instance-arn $SSO_INSTANCE_ARN \
        --target-id "$account_id" \
        --target-type AWS_ACCOUNT \
        --permission-set-arn "$permission_set_arn" \
        --principal-type USER \
        --principal-id "$USER_ID" 2>/dev/null
        
    if [ $? -eq 0 ]; then
        echo "✅ Assigned $permission_set_name to $account_name"
    else
        echo "⚠️  Assignment may already exist for $account_name"
    fi
}

# Load account IDs if available
if [ -f .env ]; then
    source .env
    echo "📋 Assigning user to accounts..."
    
    # Assign to management account
    assign_user_to_account "$management_account_id" "Management" "$ADMIN_PS_ARN" "AdminAccess"
    
    # Assign to workload accounts with appropriate permissions
    assign_user_to_account "$dev_account_id" "Development" "$DEV_PS_ARN" "DeveloperAccess"
    assign_user_to_account "$staging_account_id" "Staging" "$DEV_PS_ARN" "DeveloperAccess"
    assign_user_to_account "$shared_account_id" "Shared Services" "$DEV_PS_ARN" "DeveloperAccess"
    assign_user_to_account "$prod_account_id" "Production" "$ADMIN_PS_ARN" "AdminAccess"
else
    echo "⚠️  .env file not found. Run ./scripts/get-account-ids.sh first to assign users to workload accounts"
fi

# Get SSO start URL
SSO_START_URL=$(aws sso-admin describe-instance \
    --instance-arn $SSO_INSTANCE_ARN \
    --query 'AccessUrl' --output text)

echo ""
echo "🎉 SSO setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Permission sets created: DeveloperAccess, AdminAccess, ReadOnlyAccess"
echo "  - User created: $SSO_USERNAME ($SSO_EMAIL)"
echo "  - Account assignments completed (where accounts are available)"
echo ""
echo "🌐 Your SSO Access Portal URL:"
echo "  $SSO_START_URL"
echo ""
echo "📱 Next steps:"
echo "1. Bookmark your SSO Access Portal URL"
echo "2. Visit the URL and set up your password"
echo "3. Configure MFA when prompted"
echo "4. Test access to your assigned accounts"
echo ""
echo "💻 For CLI access, run:"
echo "  aws configure sso"
echo "  # Use SSO start URL: $SSO_START_URL"
echo "  # Select your account and role when prompted"