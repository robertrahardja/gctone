#!/bin/bash

# load environment variables
source .env

echo "🔧 cdk bootstrap process"
echo "========================"
# 🇸🇬 singapore: update title to "cdk bootstrap process (singapore)"

# function to bootstrap account
bootstrap_account() {
  local account_id="$1"
  local account_name="$2"

  echo "🚀 bootstrapping $account_name ($account_id)..."
  # 🇸🇬 singapore: add "in singapore" to the message

  cdk bootstrap aws://$account_id/$aws_default_region \
    --qualifier "cdk2024" \
    --toolkit-stack-name "cdktoolkit" \
    --cloudformation-execution-policies "arn:aws:iam::aws:policy/administratoraccess" \
    --trust-accounts $management_account_id
  # 🇸🇬 singapore additions:
  # --tags region=ap-southeast-1 \
  # --tags country=singapore

  if [ $? -eq 0 ]; then
    echo "✅ $account_name bootstrapped successfully"
    # 🇸🇬 singapore: add "in singapore" to success message
  else
    echo "❌ failed to bootstrap $account_name"
    return 1
  fi
}

# bootstrap all accounts
bootstrap_account $dev_account "development"
bootstrap_account $staging_account "staging"
bootstrap_account $shared_account "shared services"
bootstrap_account $prod_account "production"

echo "✅ all accounts bootstrapped successfully!"
