#!/bin/bash

set -e

echo "🚀 complete simple control tower + cdk v2 setup"
echo "==============================================="
# 🇸🇬 singapore: update title to include "(singapore edition)"

# step 1: prerequisites
echo "📋 step 1: checking prerequisites..."
# 🇸🇬 singapore: add region verification step here

node_version=$(node --version)
if echo "$node_version" | grep -qe "v(20|22)\."; then
  echo "✅ node.js version: $node_version"
else
  echo "❌ node.js version $node_version not supported. need v20+ or v22+"
  exit 1
fi

cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
  echo "✅ cdk version: $cdk_version"
else
  echo "❌ cdk version $cdk_version not supported. need cdk v2"
  exit 1
fi

# step 2: build project
echo "📋 step 2: building project..."
npm run build

if [ $? -eq 0 ]; then
  echo "✅ project built successfully"
else
  echo "❌ project build failed"
  exit 1
fi

# step 3: synthesize cdk
echo "📋 step 3: synthesizing cdk..."
cdk synth

if [ $? -eq 0 ]; then
  echo "✅ cdk synthesis completed"
else
  echo "❌ cdk synthesis failed"
  exit 1
fi

# step 4: check control tower
echo "📋 step 4: checking control tower status..."

# note: this requires control tower to be manually set up first
echo "⚠️  manual setup required:"
echo "1. go to aws control tower console"
# 🇸🇬 singapore: add specific url
# echo "1. go to: https://ap-southeast-1.console.aws.amazon.com/controltower/"
echo "2. click 'set up landing zone'"
# 🇸🇬 singapore: add region selection step
# echo "3. select home region: asia pacific (singapore) ap-southeast-1"
# echo "4. optional: add sydney (ap-southeast-2) for disaster recovery"
echo "3. configure with your email addresses from accounts.ts"
echo "4. wait for setup to complete (30-45 minutes)"
echo "5. re-run this script after control tower is ready"

# check if control tower is available
aws controltower list-landing-zones 2>/dev/null >/dev/null
if [ $? -eq 0 ]; then
  echo "✅ control tower cli access confirmed"
else
  echo "⚠️  control tower not available yet"
  echo "continue with manual setup and run the remaining steps manually"
fi

# step 5: get account ids
echo "📋 step 5: getting account ids..."
./scripts/get-account-ids.sh

# step 6: bootstrap accounts
echo "📋 step 6: bootstrapping accounts..."
./scripts/bootstrap-accounts.sh

# step 7: deploy applications
echo "📋 step 7: deploying applications..."
./scripts/deploy-applications.sh

# step 8: validate
echo "📋 step 8: validating deployment..."
./scripts/validate-deployment.sh

echo ""
echo "🎉 simple control tower + cdk v2 setup complete!"
echo ""
echo "📊 what was deployed:"
echo "├── 💻 development: cost-optimized, minimal resources"
echo "├── 🧪 staging: pre-production testing"
echo "├── 🔧 shared services: shared resources"
echo "└── 🚀 production: full resources"
echo ""
echo "🔗 your hello world applications:"
for env in dev staging shared prod; do
  if [ -f "outputs-$env.json" ]; then
    url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
    echo "├── $env: $url"
  fi
done
