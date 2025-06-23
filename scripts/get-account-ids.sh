#!/bin/bash

echo "🔍 getting account ids from control tower deployment..."
# 🇸🇬 singapore: this script works the same regardless of region

# function to get account id by name
get_account_id() {
  local account_name="$1"
  aws organizations list-accounts \
    --query "accounts[?name=='$account_name'].id" \
    --output text 2>/dev/null
}

# get account ids
prod_account=$(get_account_id "production")
staging_account=$(get_account_id "staging")
dev_account=$(get_account_id "development")
shared_account=$(get_account_id "shared-services")

# store in environment file
cat >.env <<eof
# account ids (generated $(date))
prod_account_id=$prod_account
staging_account_id=$staging_account
dev_account_id=$dev_account
shared_account_id=$shared_account

# management account
management_account_id=$(aws sts get-caller-identity --query account --output text)

# 🇸🇬 singapore additions:
# aws_region=ap-southeast-1
# aws_default_region=ap-southeast-1
# country=singapore
# timezone=asia/singapore
# currency=sgd
eof

echo "📋 account ids found:"
echo "├── management: $(aws sts get-caller-identity --query account --output text)"
echo "├── production: $prod_account"
echo "├── staging: $staging_account"
echo "├── development: $dev_account"
echo "└── shared services: $shared_account"

echo "💾 account ids saved to .env file"
