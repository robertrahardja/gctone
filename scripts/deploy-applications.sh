#!/bin/bash

# load environment variables
source .env

echo "🚀 deploying hello world applications"
echo "===================================="
# 🇸🇬 singapore: update title to include "(singapore)"

# function to deploy to specific account
deploy_to_account() {
  local env_name="$1"
  local account_id="$2"
  local stack_name="helloworld-$env_name"

  echo "📦 deploying $stack_name to account $account_id..."
  # 🇸🇬 singapore: add "in singapore" to deployment message

  cdk deploy $stack_name \
    --context accountid=$account_id \
    --require-approval never \
    --outputs-file "outputs-$env_name.json"

  if [ $? -eq 0 ]; then
    echo "✅ $stack_name deployed successfully"

    # extract and test api url
    api_url=$(cat "outputs-$env_name.json" | jq -r ".[\"$stack_name\"].apiurl" 2>/dev/null)
    if [ "$api_url" != "null" ] && [ ! -z "$api_url" ]; then
      echo "🌐 api url: $api_url"

      # test the endpoint
      echo "🧪 testing endpoint..."
      response=$(curl -s "$api_url" 2>/dev/null)
      if echo "$response" | grep -q "hello"; then
        echo "✅ endpoint test successful"
      else
        echo "⚠️  endpoint test failed"
      fi
    fi
  else
    echo "❌ failed to deploy $stack_name"
    return 1
  fi
  echo ""
}

# deploy to each environment (dev -> staging -> shared -> prod)
deploy_to_account "dev" $dev_account
deploy_to_account "staging" $staging_account
deploy_to_account "shared" $shared_account
deploy_to_account "prod" $prod_account

echo "🎉 all applications deployed successfully!"
echo ""
echo "🔗 access your applications:"
for env in dev staging shared prod; do
  if [ -f "outputs-$env.json" ]; then
    url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
    echo "├── $env: $url"
  fi
done
