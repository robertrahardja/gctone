#!/bin/bash

# Script Purpose: Retrieve AWS account IDs from Control Tower deployment
# This script queries AWS Organizations to get the numeric account IDs for all
# workload accounts created by Control Tower, then stores them in a .env file
# for use by other deployment scripts (bootstrap, deploy, etc.)

# Set AWS profile for SSO authentication
# Change this to match your SSO profile name
AWS_PROFILE="${AWS_PROFILE:-tar}"

echo "🔍 getting account ids from control tower deployment..."
echo "📋 using AWS profile: $AWS_PROFILE"
# 🇸🇬 singapore: this script works the same regardless of region

# Function to query AWS Organizations and get account ID by account name
# Takes account name as parameter and returns the numeric account ID
get_account_id() {
  local account_name="$1"
  # Query AWS Organizations API to list all accounts in the organization
  # Filter by account name and return only the account ID
  aws organizations list-accounts \
    --profile "$AWS_PROFILE" \
    --query "Accounts[?Name=='$account_name'].Id" \
    --output text 2>/dev/null
}

# Query each workload account created by Control Tower
# These names must match exactly what was used during Control Tower account creation
prod_account=$(get_account_id "Production")
staging_account=$(get_account_id "Staging")
dev_account=$(get_account_id "Development")
shared_account=$(get_account_id "Shared Services")

# Create .env file with all account IDs for use by other scripts
# This file will be sourced by bootstrap-accounts.sh and deploy-applications.sh
cat >.env <<eof
# account ids (generated $(date))
# These variables are used by CDK deployment scripts to target specific accounts
prod_account_id=$prod_account
staging_account_id=$staging_account
dev_account_id=$dev_account
shared_account_id=$shared_account

# management account (the account you're currently logged into)
# This is used for cross-account trust relationships during CDK bootstrap
management_account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)

# 🇸🇬 singapore additions:
# aws_region=ap-southeast-1
# aws_default_region=ap-southeast-1
# country=singapore
# timezone=asia/singapore
# currency=sgd
eof

# Display summary of found account IDs for verification
echo "📋 account ids found:"
echo "├── management: $(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)"
echo "├── production: $prod_account"
echo "├── staging: $staging_account"
echo "├── development: $dev_account"
echo "└── shared services: $shared_account"

echo "💾 account ids saved to .env file"
