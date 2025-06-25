#!/bin/bash

echo "🔍 comprehensive deployment validation"
echo "======================================"
# 🇸🇬 singapore: add "(singapore)" to title

# load environment variables
source .env 2>/dev/null || echo "⚠️  .env file not found"

# check cdk version
cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
  echo "✅ cdk version: $cdk_version"
else
  echo "❌ cdk version: $cdk_version (expected cdk v2)"
fi

# check node.js version
node_version=$(node --version 2>/dev/null)
if echo "$node_version" | grep -qe "v(20|22)\."; then
  echo "✅ node.js version: $node_version"
else
  echo "⚠️  node.js version: $node_version (recommended: v20+ or v22+)"
fi

# test applications
environments=("dev" "staging" "shared" "prod")

for env in "${environments[@]}"; do
  echo ""
  echo "🧪 testing $env environment..."

  # get api url
  api_url=""
  if [ -f "outputs-$env.json" ]; then
    api_url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
  fi

  if [ ! -z "$api_url" ] && [ "$api_url" != "null" ]; then
    echo "🌐 api url: $api_url"

    # test main endpoint
    response=$(curl -s --max-time 10 "$api_url" 2>/dev/null)
    if echo "$response" | grep -q "hello"; then
      echo "✅ main endpoint working"

      # extract environment from response
      env_from_response=$(echo "$response" | jq -r '.environment' 2>/dev/null)
      if [ "$env_from_response" = "$env" ]; then
        echo "✅ environment validation passed"
      else
        echo "⚠️  environment mismatch: expected $env, got $env_from_response"
      fi
    else
      echo "❌ main endpoint test failed"
    fi

    # test health endpoint
    health_url="${api_url%/}/health"
    health_response=$(curl -s --max-time 10 "$health_url" 2>/dev/null)
    if echo "$health_response" | grep -q "healthy"; then
      echo "✅ health endpoint working"
    else
      echo "⚠️  health endpoint test failed"
    fi
  else
    echo "❌ stack not found or not deployed: helloworld-$env"
  fi
done

echo ""
echo "📊 validation summary"
echo "===================="
echo "✅ validation completed at $(date)"
echo ""
echo "🚀 next steps:"
echo "1. access your hello world applications using the urls above"
echo "2. monitor costs in aws cost explorer"
echo "3. set up ci/cd pipeline: dev → staging → prod"
echo "4. add your custom applications to each environment"
