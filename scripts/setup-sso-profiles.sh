#!/bin/bash

# AWS SSO Profile Setup Script for Control Tower Multi-Account
# ===========================================================
# This script helps set up individual AWS SSO profiles for each workload account
# Required for CDK bootstrap operations when using AWS SSO

# Load environment variables
source .env

echo "🔧 AWS SSO Profile Setup for Multi-Account CDK Bootstrap"
echo "========================================================"
echo ""
echo "To enable CDK bootstrap across all accounts, you need to create"
echo "individual AWS SSO profiles for each workload account."
echo ""

echo "📋 Run these commands to set up the required profiles:"
echo ""

echo "1️⃣  Development Account Profile:"
echo "   aws configure sso --profile tar-dev"
echo "   SSO Session: (use existing or create new)"
echo "   Account ID: $dev_account_id"
echo "   Role: AWSAdministratorAccess"
echo "   Region: ${aws_default_region:-us-east-1}"
echo ""

echo "2️⃣  Staging Account Profile:"
echo "   aws configure sso --profile tar-staging"
echo "   SSO Session: (use same as above)"
echo "   Account ID: $staging_account_id"
echo "   Role: AWSAdministratorAccess"
echo "   Region: ${aws_default_region:-us-east-1}"
echo ""

echo "3️⃣  Shared Services Account Profile:"
echo "   aws configure sso --profile tar-shared"
echo "   SSO Session: (use same as above)"
echo "   Account ID: $shared_account_id"
echo "   Role: AWSAdministratorAccess"
echo "   Region: ${aws_default_region:-us-east-1}"
echo ""

echo "4️⃣  Production Account Profile:"
echo "   aws configure sso --profile tar-prod"
echo "   SSO Session: (use same as above)"
echo "   Account ID: $prod_account_id"
echo "   Role: AWSAdministratorAccess"
echo "   Region: ${aws_default_region:-us-east-1}"
echo ""

echo "💡 Tips:"
echo "  • Use the same SSO session name for all profiles"
echo "  • Select 'AWSAdministratorAccess' role for each account"
echo "  • Use region: ${aws_default_region:-us-east-1}"
echo ""

echo "✅ After setting up profiles, run:"
echo "   AWS_PROFILE=tar ./scripts/bootstrap-accounts.sh"
echo ""

echo "🔍 To verify profiles are set up correctly:"
echo "   aws configure list-profiles | grep tar-"
echo ""