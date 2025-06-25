#!/bin/bash

# CDK Bootstrap Script for Multi-Account Control Tower Setup
# ==========================================================
# This script prepares all AWS workload accounts for CDK deployments by:
# 1. Installing the CDK toolkit stack in each account
# 2. Creating necessary IAM roles and S3 buckets for deployments
# 3. Setting up cross-account trust relationships
#
# IMPORTANT: This must be run AFTER Control Tower creates the workload accounts
# and BEFORE any CDK deployments can happen.
#
# AWS SSO LIMITATION: This script requires individual AWS SSO profiles for each account
# because SSO roles don't have cross-account assume role permissions by default.

# Load environment variables containing account IDs
# The .env file is created by ./scripts/get-account-ids.sh and contains:
# - dev_account_id, staging_account_id, shared_account_id, prod_account_id
# - management_account_id (the account you're currently logged into)
source .env

# Verify we have the required environment variables
# This checks if ANY of the account ID variables are empty or unset
# The -z test returns TRUE if a variable is empty (zero length)
# The || operator means "OR" - if ANY condition is true, the whole expression is true
# So this reads as: "If dev_account_id is empty OR staging_account_id is empty OR..."
if [ -z "$dev_account_id" ] || [ -z "$staging_account_id" ] || [ -z "$shared_account_id" ] || [ -z "$prod_account_id" ]; then
    # If we get here, at least one required account ID is missing
    echo "❌ Missing account IDs in .env file"
    echo "💡 Run ./scripts/get-account-ids.sh first to populate account IDs"
    exit 1  # Stop the script immediately - can't bootstrap without account IDs
fi

echo "🔧 CDK Bootstrap Process for Multi-Account Setup"
echo "================================================"
echo "This will prepare all workload accounts for CDK deployments..."
echo ""
echo "📋 Accounts to bootstrap:"
echo "  • Development: $dev_account_id"
echo "  • Staging: $staging_account_id"  
echo "  • Shared Services: $shared_account_id"
echo "  • Production: $prod_account_id"
echo "  • Management (current): $management_account_id"
echo ""

# Function to bootstrap a single AWS account for CDK
# This creates the necessary infrastructure in each account for CDK deployments
bootstrap_account() {
    local account_id="$1"
    local account_name="$2"
    local profile_suffix="$3"

    echo "🚀 Bootstrapping $account_name account ($account_id)..."
    echo "   This creates CDK toolkit resources in the target account..."

    # Use the SSO profile for the specific account
    # Map profile suffix to the correct profile name
    local target_profile=""
    case "$profile_suffix" in
        "dev") target_profile="tar-dev" ;;
        "staging") target_profile="tar-staging" ;;
        "shared") target_profile="tar-shared" ;;
        "prod") target_profile="tar-prod" ;;
        *) target_profile="tar-$profile_suffix" ;;
    esac
    
    echo "   🔑 Using SSO profile: $target_profile"
    
    # Bootstrap using the SSO profile
    AWS_PROFILE="$target_profile" cdk bootstrap aws://$account_id/ap-southeast-1 \
        --qualifier "cdk2024" \
        --toolkit-stack-name "cdktoolkit" \
        --cloudformation-execution-policies "arn:aws:iam::aws:policy/AdministratorAccess" \
        --trust-accounts $management_account_id \
        --force
    
    bootstrap_result=$?

    # The cdk bootstrap command creates:
    # 1. S3 bucket for storing CDK assets (Lambda code, Docker images)
    # 2. IAM roles for CloudFormation execution
    # 3. ECR repository for Docker images (if needed)
    # 4. SSM parameters for configuration

    # Parameter explanations:
    # --qualifier "cdk2024": Unique identifier for this CDK toolkit (prevents conflicts)
    # --toolkit-stack-name "cdktoolkit": Name of the CloudFormation stack created
    # --cloudformation-execution-policies: IAM policy for CloudFormation to use
    # --trust-accounts: Allow management account to deploy to this account
    
    # Check if the bootstrap was successful
    if [ $bootstrap_result -eq 0 ]; then
        echo "   ✅ $account_name account bootstrapped successfully"
        echo "   📦 CDK toolkit stack created with S3 bucket and IAM roles"
        echo ""
    else
        echo "   ❌ Failed to bootstrap $account_name account"
        echo ""
        echo "   💡 SOLUTION: SSO profile $target_profile may not exist or have access:"
        echo "      Check: aws sts get-caller-identity --profile $target_profile"
        echo "      Or run: ./scripts/setup-automated-sso.sh to recreate profiles"
        echo ""
        echo "   💡 Alternative: Contact your AWS administrator to configure cross-account"
        echo "      assume role permissions for your SSO role"
        return 1
    fi
}

echo "🔄 Starting bootstrap process for all accounts..."
echo "This may take 2-3 minutes per account..."
echo ""
echo "💡 If you encounter authentication errors, run:"
echo "   ./scripts/setup-sso-profiles.sh"
echo "   to set up individual AWS SSO profiles for each account"
echo ""

# Bootstrap each workload account in order
# Each bootstrap creates ~5-10 AWS resources in the target account
bootstrap_account $dev_account_id "Development" "dev"
bootstrap_account $staging_account_id "Staging" "staging"
bootstrap_account $shared_account_id "Shared Services" "shared"
bootstrap_account $prod_account_id "Production" "prod"

echo "🎉 All accounts bootstrapped successfully!"
echo ""
echo "📋 What was created in each account:"
echo "  • CDK toolkit CloudFormation stack"
echo "  • S3 bucket for CDK assets (encrypted)"
echo "  • IAM execution role for CloudFormation"
echo "  • Cross-account trust relationship with management account"
echo ""
echo "🚀 Next steps:"
echo "  1. Run ./scripts/deploy-applications.sh to deploy your applications"
echo "  2. Applications will be deployed to all environments automatically"
echo ""
echo "💡 Troubleshooting:"
echo "  • If deployment fails: Check IAM permissions and account access"
echo "  • If 'already exists' errors: Bootstrap only needs to run once per account"
echo "  • If trust errors: Verify management_account_id in .env is correct"
