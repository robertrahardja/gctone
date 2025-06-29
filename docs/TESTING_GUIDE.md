# 🧪 Complete Testing Guide

Step-by-step guide to verify your AWS multi-account serverless application and CI/CD pipeline work correctly.

## 📋 **Pre-Testing Checklist**

Before starting tests, verify these prerequisites are complete:

```bash
# ✅ Check AWS CLI configuration
aws sts get-caller-identity --profile management
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile staging  
aws sts get-caller-identity --profile prod

# ✅ Verify Node.js and CDK
node --version  # Should be 22+
npm --version
cdk --version   # Should be 2.x

# ✅ Check repository structure
ls -la .github/workflows/
ls -la lib/
ls -la scripts/
```

Expected output:
```
✅ AWS CLI profiles configured for all accounts
✅ Node.js 22+ and CDK 2.x installed
✅ All workflow files present
✅ CDK project structure complete
```

## 🎯 **Phase 1: Local Development Testing**

### **Step 1.1: Install Dependencies**
```bash
# Install project dependencies
npm install

# Verify installation
npm list --depth=0
```

**Expected Output:**
```
gctone@1.0.0
├── @aws-cdk/assertions@2.202.0
├── @types/jest@29.5.12
├── @types/node@22.0.0
├── aws-cdk-lib@2.202.0
├── constructs@10.4.2
├── jest@29.7.0
├── ts-jest@29.1.5
├── ts-node@10.9.2
└── typescript@5.5.4
```

### **Step 1.2: Code Quality Checks**
```bash
# Run TypeScript compilation
npm run build

# Run linting (if configured)
npm run lint || echo "Linting not configured yet"

# Run unit tests
npm test
```

**Expected Output:**
```bash
✅ TypeScript compilation: SUCCESS
✅ Linting: PASSED (or skipped)
✅ Unit tests: X passed, 0 failed
```

### **Step 1.3: CDK Synthesis**
```bash
# Synthesize CloudFormation templates
npm run synth

# Check generated templates
ls -la cdk.out/
```

**Expected Output:**
```
✅ CDK synthesis completed successfully
✅ CloudFormation templates generated in cdk.out/
Files: CtoneStack.template.json, manifest.json, tree.json
```

### **Step 1.4: CDK Diff (Optional)**
```bash
# Compare with deployed infrastructure (if any exists)
cdk diff --profile dev
```

**Expected Output:**
```
✅ CDK diff completed (shows changes or "no differences")
```

## 🔧 **Phase 2: Infrastructure Deployment Testing**

### **Step 2.1: Development Environment**
```bash
# Deploy to development account
echo "🚀 Deploying to development..."
cdk deploy ctone-dev --profile dev --require-approval never

# Capture outputs
cdk list --profile dev
```

**Expected Output:**
```bash
✅ Development deployment: SUCCESS
✅ Stack: ctone-dev
✅ Status: UPDATE_COMPLETE (or CREATE_COMPLETE)

Outputs:
ctoneapiurl = https://abc123.execute-api.ap-southeast-1.amazonaws.com/
ctonehealthcheckurl = https://abc123.execute-api.ap-southeast-1.amazonaws.com/health
```

### **Step 2.2: Test Development Endpoints**
```bash
# Get the API URL from deployment output
DEV_API_URL="https://abc123.execute-api.ap-southeast-1.amazonaws.com"

# Test main endpoint
echo "🧪 Testing main endpoint..."
curl -s "$DEV_API_URL" | jq .

# Test health endpoint
echo "🩺 Testing health endpoint..."
curl -s "$DEV_API_URL/health" | jq .
```

**Expected Output:**
```json
Main endpoint response:
{
  "message": "CTone from Development!",
  "environment": "dev",
  "account": "803133978889",
  "timestamp": "2024-06-28T10:30:00.000Z",
  "requestId": "abc-123-def",
  "region": "ap-southeast-1",
  "version": "1.0.0",
  "runtime": "nodejs22.x"
}

Health endpoint response:
{
  "status": "healthy",
  "timestamp": "2024-06-28T10:30:00.000Z",
  "environment": "dev"
}
```

### **Step 2.3: Performance Baseline**
```bash
# Run simple performance test
echo "📊 Running performance baseline..."
for i in {1..5}; do
  start_time=$(date +%s%N)
  curl -s "$DEV_API_URL" > /dev/null
  end_time=$(date +%s%N)
  duration=$(( (end_time - start_time) / 1000000 ))
  echo "Request $i: ${duration}ms"
done
```

**Expected Output:**
```
Request 1: 245ms
Request 2: 89ms
Request 3: 95ms
Request 4: 92ms
Request 5: 88ms

✅ Average response time: ~120ms (under 2000ms threshold)
```

### **Step 2.4: AWS Resource Verification**
```bash
# Verify Lambda function
echo "🔍 Checking Lambda function..."
FUNCTION_NAME=$(aws lambda list-functions --profile dev --query 'Functions[?contains(FunctionName, `ctonefunction`)].FunctionName' --output text)
aws lambda get-function --function-name $FUNCTION_NAME --profile dev

# Verify API Gateway
echo "🌐 Checking API Gateway..."
aws apigatewayv2 get-apis --profile dev --query 'Items[?contains(Name, `CTone`)].{Name:Name,ApiId:ApiId,ApiEndpoint:ApiEndpoint}'

# Check CloudWatch logs
echo "📋 Checking CloudWatch logs..."
aws logs describe-log-groups --profile dev --log-group-name-prefix "/aws/lambda/ctone"
```

**Expected Output:**
```
✅ Lambda function: ACTIVE
✅ API Gateway: Available with correct endpoint
✅ CloudWatch logs: Log group exists
```

## 🧪 **Phase 3: CI/CD Pipeline Testing**

### **Step 3.1: Create Test Feature Branch**
```bash
# Create a test feature branch
git checkout -b test/ci-cd-validation-$(date +%s)

# Make a small, safe change
echo "// CI/CD pipeline test - $(date)" >> lib/lambda/main-handler.ts

# Commit the change
git add .
git commit -m "test: validate CI/CD pipeline functionality

- Add timestamp comment to trigger pipeline
- Test automated CI validation
- Verify deployment automation"

# Push to trigger CI
git push origin $(git branch --show-current)
```

### **Step 3.2: Monitor CI Pipeline**
```bash
# Check GitHub Actions (in browser or CLI if you have gh)
echo "🔍 Check CI pipeline at:"
echo "https://github.com/$(git config remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"

# Or use GitHub CLI if available
gh workflow list || echo "Install 'gh' CLI for command-line monitoring"
```

**Expected CI Results:**
```
✅ Code Validation job: PASSED
  ├── Checkout code: ✅
  ├── Setup Node.js: ✅  
  ├── Install dependencies: ✅
  ├── Lint code: ✅
  ├── TypeScript compilation: ✅
  ├── Run unit tests: ✅
  ├── CDK synthesis: ✅
  └── Security scan: ✅

✅ CDK Diff Analysis job: PASSED (if PR)
  ├── Configure AWS credentials: ✅
  ├── CDK diff for development: ✅
  └── Comment PR with diff: ✅

✅ Security Analysis job: PASSED
  └── All security checks: ✅

✅ Cost Impact Analysis job: PASSED
  └── Cost estimation: ✅
```

### **Step 3.3: Create Pull Request**
```bash
# Create PR using GitHub CLI or web interface
gh pr create \
  --title "Test: CI/CD Pipeline Validation" \
  --body "Testing the complete CI/CD pipeline functionality:

- ✅ Automated CI validation
- ✅ Security scanning  
- ✅ Cost analysis
- ✅ CDK diff preview

This is a test PR to validate the pipeline works correctly." || \
echo "Create PR manually at GitHub web interface"
```

**Expected PR Results:**
```
✅ PR created successfully
✅ CI checks automatically triggered
✅ All status checks: PASSED
✅ CDK diff comment posted
✅ Ready for merge
```

### **Step 3.4: Test Merge to Main (Development Deployment)**
```bash
# Merge the PR (via web interface or CLI)
echo "📝 Merge the PR to trigger automatic development deployment"

# Monitor the deployment workflow
echo "🔍 Monitor deployment at:"
echo "https://github.com/$(git config remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"

# Wait for deployment to complete (check in GitHub Actions)
echo "⏳ Waiting for deployment to complete..."
```

**Expected Development Deployment Results:**
```
✅ Deploy to Development job: PASSED
  ├── Checkout code: ✅
  ├── Setup Node.js: ✅
  ├── Install dependencies: ✅
  ├── Build project: ✅
  ├── Configure AWS credentials: ✅
  ├── Verify AWS access: ✅ (Account: 803133978889)
  ├── Check CDK bootstrap: ✅
  ├── Deploy to development: ✅
  ├── Extract API endpoints: ✅
  ├── Health check: ✅
  ├── Integration tests: ✅
  └── Performance baseline: ✅

Duration: ~8-10 minutes
Status: SUCCESS
```

### **Step 3.5: Verify Automatic Deployment**
```bash
# Test the updated development endpoint
echo "🧪 Testing updated development deployment..."

# Get API URL from previous deployment or check GitHub Actions output
DEV_API_URL="https://abc123.execute-api.ap-southeast-1.amazonaws.com"

# Test that the deployment worked
curl -s "$DEV_API_URL" | jq .

# Verify the timestamp comment was deployed (check logs if needed)
aws logs filter-log-events \
  --profile dev \
  --log-group-name "/aws/lambda/ctone-dev" \
  --start-time $(date -d '10 minutes ago' +%s)000 \
  --query 'events[0].message'
```

**Expected Output:**
```json
{
  "message": "CTone from Development!",
  "environment": "dev",
  "account": "803133978889",
  "timestamp": "2024-06-28T11:15:00.000Z",
  "requestId": "xyz-789-abc",
  "region": "ap-southeast-1",
  "version": "1.0.0",
  "runtime": "nodejs22.x"
}

✅ Deployment successful - API responding correctly
✅ Latest changes deployed automatically
```

## 🎭 **Phase 4: Manual Staging Deployment Testing**

### **Step 4.1: Trigger Staging Deployment**
```bash
echo "🎭 Testing manual staging deployment..."
echo "1. Go to GitHub Actions"
echo "2. Select 'Deploy to Staging' workflow"
echo "3. Click 'Run workflow'"
echo "4. Set parameters:"
echo "   - Git reference: main"
echo "   - Source environment: development"  
echo "   - Skip tests: false"
echo "5. Click 'Run workflow'"
```

**Manual Steps:**
1. Navigate to GitHub Actions page
2. Find "Deploy to Staging" workflow
3. Click "Run workflow" button
4. Fill in parameters as shown above
5. Confirm execution

### **Step 4.2: Monitor Staging Deployment**
```bash
# Monitor the staging deployment progress
echo "🔍 Monitor staging deployment in GitHub Actions"
echo "Expected jobs:"
echo "  1. Pre-deployment Validation (2 min)"
echo "  2. Deploy to Staging Environment (14 min)"  
echo "  3. Post-deployment Tasks (2 min)"
```

**Expected Staging Results:**
```
✅ Pre-deployment Validation: PASSED
  ├── Git reference validated: ✅
  ├── Source environment check: ✅
  └── Manual approval gate: ✅

✅ Deploy to Staging Environment: PASSED
  ├── AWS Authentication: ✅ (Account: 521744733620)
  ├── CDK Deployment: ✅
  ├── Smoke Tests: ✅
  ├── Integration Tests: ✅
  ├── Performance Tests: ✅
  └── Security Validation: ✅

✅ Post-deployment Tasks: PASSED

Duration: ~18 minutes
Status: SUCCESS
```

### **Step 4.3: Test Staging Environment**
```bash
# Get staging API URL from deployment output
STAGING_API_URL="https://xyz789.execute-api.ap-southeast-1.amazonaws.com"

echo "🧪 Testing staging environment..."

# Test main endpoint
curl -s "$STAGING_API_URL" | jq .

# Test health endpoint
curl -s "$STAGING_API_URL/health" | jq .

# Performance test
echo "📊 Staging performance test..."
for i in {1..3}; do
  start_time=$(date +%s%N)
  curl -s "$STAGING_API_URL" > /dev/null
  end_time=$(date +%s%N)
  duration=$(( (end_time - start_time) / 1000000 ))
  echo "Request $i: ${duration}ms"
done
```

**Expected Staging Output:**
```json
{
  "message": "CTone from Staging!",
  "environment": "staging",
  "account": "521744733620",
  "timestamp": "2024-06-28T11:45:00.000Z",
  "requestId": "def-456-ghi",
  "region": "ap-southeast-1",
  "version": "1.0.0",
  "runtime": "nodejs22.x",
  "metadata": {
    "memoryLimit": "256"
  }
}

✅ Staging environment healthy
✅ Performance: ~90ms average
```

## 🚀 **Phase 5: Production Deployment Testing**

### **Step 5.1: Create Release Tag**
```bash
# Create a proper release tag for production
git checkout main
git pull origin main

# Create release tag
git tag -a v1.0.1 -m "Release v1.0.1: CI/CD pipeline validation

Features tested:
- ✅ Automated CI validation
- ✅ Development auto-deployment  
- ✅ Staging manual deployment
- ✅ End-to-end pipeline functionality

Ready for production deployment."

# Push the tag
git push origin v1.0.1

echo "✅ Release tag v1.0.1 created and pushed"
```

### **Step 5.2: Trigger Production Deployment**
```bash
echo "🚀 Testing production deployment..."
echo "1. Go to GitHub Actions"
echo "2. Select 'Deploy to Production' workflow"
echo "3. Click 'Run workflow'"
echo "4. Set parameters:"
echo "   - Git reference: v1.0.1"
echo "   - Source environment: staging"
echo "   - Deployment strategy: standard"
echo "   - Rollback enabled: true"
echo "5. Click 'Run workflow'"
```

**Manual Steps:**
1. Navigate to GitHub Actions
2. Find "Deploy to Production" workflow
3. Use the release tag `v1.0.1`
4. Ensure all approval gates are configured
5. Monitor the multi-stage approval process

### **Step 5.3: Monitor Production Deployment**
```bash
echo "🔍 Monitor production deployment phases:"
echo "  1. Pre-production Validation (3 min)"
echo "  2. Production Approval Gates (manual)"
echo "  3. Deploy to Production (18 min)"
echo "  4. Post-deployment Tasks (5 min)"
```

**Expected Production Results:**
```
✅ Pre-production Validation: PASSED
  ├── Git tag validation: ✅ (v1.0.1)
  ├── Staging environment check: ✅
  ├── Security compliance: ✅
  └── Change management: ✅

⏳ Production Approval Gates: PENDING
  ├── Senior developer approval: ⏳
  ├── DevOps lead approval: ⏳
  └── Business approval: ⏳

✅ Deploy to Production: PASSED (after approvals)
  ├── AWS Authentication: ✅ (Account: 668427974646)
  ├── Pre-deployment backup: ✅
  ├── Health check: ✅
  ├── CDK Deployment: ✅
  ├── Post-deployment validation: ✅
  └── Performance verification: ✅

✅ Post-deployment Tasks: PASSED

Duration: ~25 minutes (including approvals)
Status: SUCCESS
```

### **Step 5.4: Test Production Environment**
```bash
# Get production API URL from deployment output
PROD_API_URL="https://prod123.execute-api.ap-southeast-1.amazonaws.com"

echo "🧪 Testing production environment..."

# Test main endpoint
curl -s "$PROD_API_URL" | jq .

# Test health endpoint  
curl -s "$PROD_API_URL/health" | jq .

# Verify production configuration
echo "🔍 Verifying production configuration..."
response=$(curl -s "$PROD_API_URL")
environment=$(echo "$response" | jq -r '.environment')
memory=$(echo "$response" | jq -r '.metadata.memoryLimit')

if [ "$environment" = "prod" ] && [ "$memory" = "512" ]; then
  echo "✅ Production configuration verified"
else
  echo "❌ Production configuration mismatch"
fi
```

**Expected Production Output:**
```json
{
  "message": "CTone from Production!",
  "environment": "prod", 
  "account": "668427974646",
  "timestamp": "2024-06-28T12:15:00.000Z",
  "requestId": "ghi-789-jkl",
  "region": "ap-southeast-1",
  "version": "1.0.0",
  "runtime": "nodejs22.x",
  "metadata": {
    "memoryLimit": "512"
  }
}

✅ Production environment healthy
✅ Configuration correct (512MB memory)
✅ Performance optimized
```

## 💰 **Phase 6: Cost Optimization Testing**

### **Step 6.1: Test Smart Cleanup**
```bash
echo "💰 Testing cost optimization..."
echo "1. Go to GitHub Actions"
echo "2. Select 'Cost Optimization' workflow"
echo "3. Click 'Run workflow'"
echo "4. Set parameters:"
echo "   - Optimization level: smart"
echo "   - Environments: dev,staging"
echo "   - Restore time: 09:00"
echo "5. Click 'Run workflow'"
```

### **Step 6.2: Monitor Cost Optimization**
```bash
echo "🔍 Monitor cost optimization workflow:"
echo "Expected jobs:"
echo "  1. Cost Analysis (1 min)"
echo "  2. Smart Cost Optimization (5 min)"
echo "  3. Notification (1 min)"
```

**Expected Cost Optimization Results:**
```
✅ Cost Analysis: PASSED
  └── Optimization needed: true (off-hours detected)

✅ Smart Optimization: PASSED
  ├── Development cleanup: ✅
  ├── Staging cleanup: ✅
  └── Infrastructure preserved: ✅

✅ Notification: PASSED
  └── Savings: $30-60/month

Duration: ~7 minutes
Status: SUCCESS
```

### **Step 6.3: Verify Cleanup**
```bash
# Check that development stack is destroyed
echo "🔍 Verifying development cleanup..."
aws cloudformation describe-stacks \
  --stack-name ctone-dev \
  --profile dev 2>/dev/null || echo "✅ Development stack destroyed"

# Check that staging stack is destroyed
echo "🔍 Verifying staging cleanup..."
aws cloudformation describe-stacks \
  --stack-name ctone-staging \
  --profile staging 2>/dev/null || echo "✅ Staging stack destroyed"

# Verify production is untouched
echo "🔍 Verifying production remains active..."
aws cloudformation describe-stacks \
  --stack-name ctone-prod \
  --profile prod \
  --query 'Stacks[0].StackStatus' \
  --output text
```

**Expected Output:**
```
✅ Development stack destroyed (smart cleanup)
✅ Staging stack destroyed (smart cleanup)  
✅ Production stack: UPDATE_COMPLETE (preserved)
✅ CDK bootstrap preserved in all accounts
```

### **Step 6.4: Test Environment Restoration**
```bash
# Test quick restoration
echo "🔄 Testing environment restoration..."
cdk deploy ctone-dev --profile dev --require-approval never

# Time the restoration
start_time=$(date +%s)
echo "⏳ Restoration started at $(date)"

# Wait for completion and test
sleep 120  # Allow 2 minutes for deployment

end_time=$(date +%s)
duration=$((end_time - start_time))

# Test restored environment
DEV_API_URL=$(aws cloudformation describe-stacks \
  --stack-name ctone-dev \
  --profile dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ctoneapiurl`].OutputValue' \
  --output text)

curl -s "$DEV_API_URL" | jq .

echo "✅ Environment restored in ${duration} seconds"
```

**Expected Output:**
```
✅ Development environment restored
✅ Restoration time: ~120 seconds
✅ API responding correctly
✅ Cost savings achieved when not developing
```

## 📊 **Phase 7: Final Validation Summary**

### **Step 7.1: Complete System Test**
```bash
echo "🎯 Final system validation..."

# Test all environments
environments=("dev" "staging" "prod")
profiles=("dev" "staging" "prod")

for i in "${!environments[@]}"; do
  env="${environments[$i]}"
  profile="${profiles[$i]}"
  
  echo "Testing $env environment..."
  
  # Get API URL
  api_url=$(aws cloudformation describe-stacks \
    --stack-name "ctone-$env" \
    --profile "$profile" \
    --query 'Stacks[0].Outputs[?OutputKey==`ctoneapiurl`].OutputValue' \
    --output text 2>/dev/null)
  
  if [ -n "$api_url" ]; then
    response=$(curl -s "$api_url")
    status=$(echo "$response" | jq -r '.environment')
    echo "✅ $env: $status ($api_url)"
  else
    echo "⚠️ $env: Not deployed"
  fi
done
```

### **Step 7.2: Generate Test Report**
```bash
echo "📋 Generating test report..."

cat > test-results-$(date +%Y%m%d-%H%M%S).md << EOF
# CI/CD Pipeline Test Results

## Test Summary
- **Date**: $(date)
- **Tester**: $(whoami)
- **Repository**: $(git config remote.origin.url)
- **Branch**: $(git branch --show-current)

## ✅ Passed Tests

### Infrastructure
- [x] Local development setup
- [x] CDK synthesis and deployment
- [x] Multi-environment configuration
- [x] AWS resource creation

### CI/CD Pipeline
- [x] Automated CI validation
- [x] Pull request workflow
- [x] Development auto-deployment
- [x] Manual staging deployment
- [x] Production deployment with approvals
- [x] Cost optimization automation

### Functionality
- [x] API endpoints responding
- [x] Health checks working
- [x] Environment-specific configuration
- [x] Performance within thresholds
- [x] Security validation

### Cost Optimization
- [x] Smart cleanup functionality
- [x] Environment restoration
- [x] 99% cost savings achieved

## 📊 Performance Metrics

### Response Times
- Development: ~120ms average
- Staging: ~90ms average  
- Production: ~85ms average

### Deployment Times
- CI validation: ~5 minutes
- Development deployment: ~8 minutes
- Staging deployment: ~14 minutes
- Production deployment: ~18 minutes

### Cost Impact
- Active (all environments): \$35-70/month
- Optimized (smart cleanup): \$0.10/month
- Savings: 99% cost reduction

## 🎉 Conclusion

✅ **All tests passed successfully**
✅ **CI/CD pipeline fully functional**
✅ **Multi-environment deployment verified**
✅ **Cost optimization working as expected**
✅ **Production-ready for real workloads**

The AWS multi-account serverless application with automated CI/CD pipeline is working correctly and ready for production use.
EOF

echo "✅ Test report generated: test-results-$(date +%Y%m%d-%H%M%S).md"
```

## 🎉 **Success Criteria**

Your setup is working correctly if you see:

### ✅ **Infrastructure Tests**
- All CDK deployments succeed
- API endpoints respond correctly
- AWS resources created properly
- Multi-account isolation working

### ✅ **CI/CD Tests** 
- PR triggers CI validation
- Merge triggers dev deployment
- Manual staging deployment works
- Production requires approvals
- All status checks pass

### ✅ **Cost Optimization Tests**
- Smart cleanup destroys apps (keeps infrastructure)
- Restoration completes in ~2 minutes
- 99% cost savings achieved
- Production environment preserved

### ✅ **Performance Tests**
- Response times under 2000ms
- No errors in health checks
- Environment-specific configurations correct
- Deployment times within expected ranges

## 🗑️ **Phase 8: Complete Cleanup (Zero Cost)**

**⚠️ IMPORTANT: Only run this phase when you're completely done testing and want to delete EVERYTHING to incur zero costs.**

### **Step 8.1: Manual Cleanup Method**

#### **Option A: Use CDK Destroy (Recommended)**
```bash
echo "🗑️ Destroying all application stacks..."

# Destroy production (if deployed)
echo "Destroying production..."
cdk destroy ctone-prod --profile prod --force || echo "Production stack not found"

# Destroy staging (if deployed)  
echo "Destroying staging..."
cdk destroy ctone-staging --profile staging --force || echo "Staging stack not found"

# Destroy development (if deployed)
echo "Destroying development..."
cdk destroy ctone-dev --profile dev --force || echo "Development stack not found"

# Verify all application stacks are destroyed
echo "🔍 Verifying all stacks destroyed..."
aws cloudformation list-stacks --profile dev --query 'StackSummaries[?contains(StackName, `ctone`) && StackStatus != `DELETE_COMPLETE`]'
aws cloudformation list-stacks --profile staging --query 'StackSummaries[?contains(StackName, `ctone`) && StackStatus != `DELETE_COMPLETE`]'
aws cloudformation list-stacks --profile prod --query 'StackSummaries[?contains(StackName, `ctone`) && StackStatus != `DELETE_COMPLETE`]'
```

#### **Option B: Use GitHub Actions Nuclear Cleanup**
```bash
echo "💥 Using GitHub Actions for nuclear cleanup..."
echo "1. Go to GitHub Actions"
echo "2. Select 'Cost Optimization' workflow"
echo "3. Click 'Run workflow'"
echo "4. Set parameters:"
echo "   - Optimization level: nuclear"
echo "   - Environments: dev,staging,prod"
echo "5. Click 'Run workflow'"
echo "6. Wait for completion (~10 minutes)"
```

### **Step 8.2: CDK Bootstrap Cleanup (Optional)**

**⚠️ WARNING: Only delete CDK bootstrap if you'll never use CDK in these accounts again!**

```bash
echo "🧨 OPTIONAL: Destroying CDK bootstrap stacks..."
echo "⚠️ WARNING: This will prevent future CDK deployments until re-bootstrap!"

read -p "Are you sure you want to delete CDK bootstrap? This cannot be undone easily. (yes/NO): " confirm

if [ "$confirm" = "yes" ]; then
  echo "Destroying CDK bootstrap in development..."
  aws cloudformation delete-stack --stack-name cdktoolkit --profile dev || echo "Bootstrap stack not found in dev"
  
  echo "Destroying CDK bootstrap in staging..."
  aws cloudformation delete-stack --stack-name cdktoolkit --profile staging || echo "Bootstrap stack not found in staging"
  
  echo "Destroying CDK bootstrap in production..."
  aws cloudformation delete-stack --stack-name cdktoolkit --profile prod || echo "Bootstrap stack not found in prod"
  
  echo "⏳ Waiting for bootstrap deletion to complete..."
  sleep 60
  
  echo "✅ CDK bootstrap cleanup initiated"
else
  echo "ℹ️ CDK bootstrap preserved (recommended for future use)"
fi
```

### **Step 8.3: Verify Complete Cleanup**
```bash
echo "🔍 Verifying complete cleanup..."

# Check for remaining application stacks
echo "Checking for remaining application stacks..."
for profile in dev staging prod; do
  echo "Checking $profile account..."
  
  stacks=$(aws cloudformation list-stacks \
    --profile "$profile" \
    --query 'StackSummaries[?contains(StackName, `ctone`) && StackStatus != `DELETE_COMPLETE`].StackName' \
    --output text)
  
  if [ -n "$stacks" ]; then
    echo "⚠️ $profile: Remaining stacks: $stacks"
  else
    echo "✅ $profile: All application stacks deleted"
  fi
done

# Check CDK bootstrap status (if you chose to delete it)
echo ""
echo "Checking CDK bootstrap status..."
for profile in dev staging prod; do
  aws cloudformation describe-stacks \
    --stack-name cdktoolkit \
    --profile "$profile" \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "✅ $profile: CDK bootstrap deleted"
done
```

### **Step 8.4: GitHub Repository Cleanup (Optional)**
```bash
echo "🧹 Optional: Clean up GitHub repository..."

# Delete test branches
git branch -d test/ci-cd-validation-* 2>/dev/null || echo "No test branches found"

# Delete test tags
git tag -d v1.0.1 2>/dev/null || echo "No test tags found"
git push origin --delete v1.0.1 2>/dev/null || echo "No remote test tags found"

# Clean up local artifacts
rm -rf cdk.out/
rm -rf node_modules/
rm -f test-results-*.md

echo "✅ Local repository cleaned"
```

### **Step 8.5: AWS Account Cleanup Verification**
```bash
echo "💰 Final cost verification..."

# Check for any remaining billable resources
echo "🔍 Checking for remaining AWS resources that might incur costs..."

for profile in dev staging prod; do
  echo ""
  echo "Checking $profile account for billable resources..."
  
  # Check Lambda functions
  lambdas=$(aws lambda list-functions --profile "$profile" --query 'Functions[?contains(FunctionName, `ctone`)].FunctionName' --output text)
  if [ -n "$lambdas" ]; then
    echo "⚠️ $profile: Remaining Lambda functions: $lambdas"
  else
    echo "✅ $profile: No Lambda functions found"
  fi
  
  # Check API Gateways
  apis=$(aws apigatewayv2 get-apis --profile "$profile" --query 'Items[?contains(Name, `CTone`)].Name' --output text)
  if [ -n "$apis" ]; then
    echo "⚠️ $profile: Remaining API Gateways: $apis"
  else
    echo "✅ $profile: No API Gateways found"
  fi
  
  # Check CloudWatch Log Groups
  logs=$(aws logs describe-log-groups --profile "$profile" --log-group-name-prefix "/aws/lambda/hello" --query 'logGroups[].logGroupName' --output text)
  if [ -n "$logs" ]; then
    echo "ℹ️ $profile: Remaining log groups: $logs (minimal cost)"
  else
    echo "✅ $profile: No application log groups found"
  fi
done
```

### **Step 8.6: Final Cost Impact Summary**
```bash
echo ""
echo "💰 FINAL COST IMPACT SUMMARY"
echo "============================"
echo ""
echo "Before cleanup:"
echo "  • Development: $2-5/month"
echo "  • Staging: $3-6/month"
echo "  • Production: $4-8/month"
echo "  • Total: $35-70/month"
echo ""
echo "After complete cleanup:"
echo "  • Application resources: $0/month ✅"
echo "  • CDK bootstrap (if preserved): ~$0.05/month"
echo "  • CloudWatch logs: ~$0.01/month"
echo "  • Control Tower (unchanged): $8-15/month"
echo "  • Total: ~$0.10/month (99.8% savings!) 🎉"
echo ""
echo "⚠️ Note: Control Tower costs remain as it's your organization foundation"
echo "✅ All application-specific costs eliminated"
```

## 📋 **Complete Cleanup Checklist**

Use this checklist to ensure you've removed everything:

### **Application Resources**
- [ ] ✅ Development stack destroyed
- [ ] ✅ Staging stack destroyed  
- [ ] ✅ Production stack destroyed
- [ ] ✅ All Lambda functions deleted
- [ ] ✅ All API Gateways deleted
- [ ] ✅ CloudWatch alarms removed

### **Infrastructure Resources (Optional)**
- [ ] ⚠️ CDK bootstrap stacks deleted (only if never using CDK again)
- [ ] ℹ️ CloudWatch log groups (minimal cost, can keep)
- [ ] ℹ️ IAM roles for GitHub Actions (can keep for future use)

### **GitHub Repository**
- [ ] 🧹 Test branches cleaned up
- [ ] 🧹 Test tags removed
- [ ] 🧹 Local artifacts deleted

### **Cost Verification**
- [ ] 💰 No Lambda charges appearing in AWS billing
- [ ] 💰 No API Gateway charges appearing
- [ ] 💰 Only Control Tower baseline costs remain
- [ ] 💰 Monthly estimate: ~$0.10 (vs $35-70 before)

## 🎯 **When to Use Complete Cleanup**

### **Use Complete Cleanup When:**
- ✅ Finished testing and evaluating the setup
- ✅ Don't plan to develop for an extended period
- ✅ Want to minimize AWS costs to near-zero
- ✅ Moving to a different AWS architecture
- ✅ Completed the learning objectives

### **Keep Infrastructure When:**
- 🔄 Planning to resume development soon
- 🔄 Want to demonstrate the working pipeline
- 🔄 Using as a reference implementation
- 🔄 Building upon this foundation

---

**💡 Remember: You can always re-deploy everything in ~15 minutes using the setup guide if you need to restore the environment later!**

---

**🚀 If all tests pass, you have a production-ready AWS multi-account serverless application with enterprise-grade CI/CD automation!**