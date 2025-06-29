#!/bin/bash

# 🔧 AWS CLI Profile Setup Script
# This script helps configure AWS CLI profiles for all accounts in your Control Tower setup

set -e

echo "🔧 AWS CLI Profile Setup for Multi-Account Control Tower"
echo "======================================================="
echo ""

# Account information from your setup
ACCOUNT_NAMES=("management" "dev" "staging" "shared" "prod")
ACCOUNT_IDS=("926352914208" "803133978889" "521744733620" "216665870694" "668427974646")

echo "📋 Your Control Tower Account Structure:"
echo "----------------------------------------"
for i in "${!ACCOUNT_NAMES[@]}"; do
    echo "  • ${ACCOUNT_NAMES[$i]}: ${ACCOUNT_IDS[$i]}"
done
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo "✅ AWS CLI found: $(aws --version)"
echo ""

# Setup method selection
echo "🔧 Choose your setup method:"
echo "1. SSO Setup (Recommended for Control Tower)"
echo "2. Access Key Setup (Manual keys)"
echo "3. Show existing profiles"
echo ""

read -p "Enter choice (1-3): " setup_choice

case $setup_choice in
    1)
        echo ""
        echo "🔐 Setting up AWS SSO profiles..."
        echo "================================="
        echo ""
        
        # Get SSO information
        echo "📝 Please provide your AWS SSO information:"
        read -p "SSO Start URL (e.g., https://your-domain.awsapps.com/start): " sso_start_url
        read -p "SSO Region (e.g., us-east-1): " sso_region
        
        echo ""
        echo "🔧 Configuring SSO profiles..."
        
        # Configure each profile
        for i in "${!ACCOUNT_NAMES[@]}"; do
            account_name="${ACCOUNT_NAMES[$i]}"
            account_id="${ACCOUNT_IDS[$i]}"
            
            echo "Setting up $account_name profile..."
            
            # Configure the profile
            aws configure set sso_start_url "$sso_start_url" --profile "$account_name"
            aws configure set sso_region "$sso_region" --profile "$account_name"
            aws configure set sso_account_id "$account_id" --profile "$account_name"
            
            # Set role name based on account type
            if [ "$account_name" = "management" ]; then
                aws configure set sso_role_name "AWSControlTowerExecution" --profile "$account_name"
            else
                aws configure set sso_role_name "AWSAdministratorAccess" --profile "$account_name"
            fi
            
            # Set default region
            aws configure set region "ap-southeast-1" --profile "$account_name"
            aws configure set output "json" --profile "$account_name"
            
            echo "✅ $account_name profile configured"
        done
        
        echo ""
        echo "🎯 SSO profiles configured successfully!"
        echo ""
        echo "📋 Next steps:"
        echo "1. Run: aws sso login --profile management"
        echo "2. Complete the browser authentication"
        echo "3. Test with: aws sts get-caller-identity --profile management"
        echo ""
        ;;
        
    2)
        echo ""
        echo "🔑 Setting up Access Key profiles..."
        echo "===================================="
        echo ""
        
        echo "⚠️  You'll need access keys for each account."
        echo "   Get these from IAM Users in each account."
        echo ""
        
        for i in "${!ACCOUNT_NAMES[@]}"; do
            account_name="${ACCOUNT_NAMES[$i]}"
            account_id="${ACCOUNT_IDS[$i]}"
            
            echo "Setting up $account_name (${account_id})..."
            echo "----------------------------------------"
            
            read -p "Access Key ID for $account_name: " access_key_id
            read -s -p "Secret Access Key for $account_name: " secret_access_key
            echo ""
            
            # Configure the profile
            aws configure set aws_access_key_id "$access_key_id" --profile "$account_name"
            aws configure set aws_secret_access_key "$secret_access_key" --profile "$account_name"
            aws configure set region "ap-southeast-1" --profile "$account_name"
            aws configure set output "json" --profile "$account_name"
            
            echo "✅ $account_name profile configured"
            echo ""
        done
        
        echo "🎯 Access key profiles configured successfully!"
        echo ""
        ;;
        
    3)
        echo ""
        echo "📋 Existing AWS CLI profiles:"
        echo "============================="
        
        if [ -f ~/.aws/config ]; then
            echo ""
            echo "Current profiles in ~/.aws/config:"
            grep -E '^\[profile ' ~/.aws/config 2>/dev/null | sed 's/\[profile /• /' | sed 's/\]//' || echo "No profiles found"
            echo ""
            
            echo "Testing existing profiles:"
            for i in "${!ACCOUNT_NAMES[@]}"; do
                account_name="${ACCOUNT_NAMES[$i]}"
                echo -n "Testing $account_name: "
                if aws sts get-caller-identity --profile "$account_name" &>/dev/null; then
                    account_id=$(aws sts get-caller-identity --profile "$account_name" --query 'Account' --output text)
                    echo "✅ Working (Account: $account_id)"
                else
                    echo "❌ Not working"
                fi
            done
        else
            echo "No AWS config file found at ~/.aws/config"
        fi
        echo ""
        ;;
        
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Verification function
verify_profiles() {
    echo "🔍 Verifying profile setup..."
    echo "============================="
    echo ""
    
    all_working=true
    
    for i in "${!ACCOUNT_NAMES[@]}"; do
        account_name="${ACCOUNT_NAMES[$i]}"
        expected_account="${ACCOUNT_IDS[$i]}"
        echo -n "Testing $account_name profile: "
        
        if actual_account=$(aws sts get-caller-identity --profile "$account_name" --query 'Account' --output text 2>/dev/null); then
            if [ "$actual_account" = "$expected_account" ]; then
                echo "✅ Working (Account: $actual_account)"
            else
                echo "⚠️  Working but wrong account (Expected: $expected_account, Got: $actual_account)"
                all_working=false
            fi
        else
            echo "❌ Not working"
            all_working=false
        fi
    done
    
    echo ""
    if [ "$all_working" = true ]; then
        echo "🎉 All profiles working correctly!"
        
        echo ""
        echo "📋 You can now use these commands:"
        echo "  aws sts get-caller-identity --profile management"
        echo "  aws sts get-caller-identity --profile dev"
        echo "  aws sts get-caller-identity --profile staging"
        echo "  aws sts get-caller-identity --profile prod"
        echo ""
        echo "🚀 Ready to proceed with CDK deployments!"
    else
        echo "⚠️  Some profiles need attention. Please check the configuration."
    fi
}

# Offer to verify profiles
if [ "$setup_choice" != "3" ]; then
    echo ""
    read -p "Would you like to test the profiles now? (y/N): " test_profiles
    
    if [[ $test_profiles =~ ^[Yy]$ ]]; then
        verify_profiles
    else
        echo ""
        echo "💡 To test profiles later, run:"
        echo "   ./scripts/setup-aws-profiles.sh"
        echo "   Then choose option 3"
    fi
fi

echo ""
echo "📚 Documentation:"
echo "  • Setup Guide: docs/SETUP_GUIDE.md"
echo "  • Testing Guide: docs/TESTING_GUIDE.md"
echo ""
echo "✅ AWS CLI profile setup complete!"