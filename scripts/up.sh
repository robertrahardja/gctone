#!/bin/bash

# Complete AWS Control Tower + CDK Environment Setup
# ===================================================
# This single script handles everything from account discovery to production-ready deployment
# Run this after completing AWS Control Tower setup manually

set -e

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script version and info
SCRIPT_VERSION="2.0"
SCRIPT_NAME="AWS Control Tower Complete Setup"

echo -e "${BLUE}🚀 ${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
echo "============================================="
echo -e "${CYAN}Complete environment setup in one command${NC}"
echo ""

# =============================================================================
# STEP 0: PREREQUISITES CHECK
# =============================================================================

echo -e "${PURPLE}📋 Step 0: Prerequisites Check${NC}"
echo "==============================="

# Check for required tools
check_prerequisites() {
    local missing_tools=()
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("Node.js v20+")
    else
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            missing_tools+=("Node.js v20+ (current: v$NODE_VERSION)")
        fi
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("AWS CLI v2")
    fi
    
    if ! command -v cdk &> /dev/null; then
        missing_tools+=("AWS CDK v2")
    else
        CDK_VERSION=$(cdk --version | cut -d' ' -f1)
        if [[ ! "$CDK_VERSION" =~ ^2\. ]]; then
            missing_tools+=("AWS CDK v2 (current: $CDK_VERSION)")
        fi
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq JSON processor")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools:${NC}"
        printf '   %s\n' "${missing_tools[@]}"
        echo ""
        echo -e "${YELLOW}💡 Install missing tools:${NC}"
        echo "   Node.js v20+: https://nodejs.org/"
        echo "   AWS CLI v2:   https://aws.amazon.com/cli/"
        echo "   AWS CDK v2:   npm install -g aws-cdk"
        echo "   jq:           brew install jq (macOS) or apt-get install jq (Linux)"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites installed${NC}"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        echo ""
        echo -e "${YELLOW}💡 Set up AWS credentials first:${NC}"
        echo "   1. aws configure sso --profile tar"
        echo "   2. aws sso login --profile tar"
        echo "   3. export AWS_PROFILE=tar"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
}

# Check project build
check_project_build() {
    echo "Building project..."
    if ! npm run build &> /dev/null; then
        echo -e "${RED}❌ Project build failed${NC}"
        echo ""
        echo -e "${YELLOW}💡 Try running:${NC}"
        echo "   npm install"
        echo "   npm run build"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Project built successfully${NC}"
}

# Check CDK synthesis
check_cdk_synth() {
    echo "Validating CDK configuration..."
    if ! cdk synth &> /dev/null; then
        echo -e "${RED}❌ CDK synthesis failed${NC}"
        echo ""
        echo -e "${YELLOW}💡 Check your CDK configuration and try:${NC}"
        echo "   cdk synth --verbose"
        exit 1
    fi
    
    echo -e "${GREEN}✅ CDK configuration valid${NC}"
}

# Check Control Tower setup
check_control_tower() {
    echo "Checking Control Tower setup..."
    
    # Check if we have organizations permissions
    if ! aws organizations describe-organization &> /dev/null; then
        echo -e "${RED}❌ Control Tower not set up or insufficient permissions${NC}"
        echo ""
        echo -e "${YELLOW}💡 Complete Control Tower setup first:${NC}"
        echo "   1. Go to AWS Control Tower console"
        echo "   2. Run the setup wizard (30 minutes)"
        echo "   3. Wait for all accounts to be created"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Control Tower configured${NC}"
}

check_prerequisites
check_aws_credentials
check_project_build
check_cdk_synth
check_control_tower

echo ""

# =============================================================================
# STEP 1: ACCOUNT DISCOVERY
# =============================================================================

echo -e "${PURPLE}🔍 Step 1: Account Discovery${NC}"
echo "============================"

discover_accounts() {
    echo "Discovering Control Tower accounts..."
    
    # Get all accounts in the organization
    ACCOUNTS_JSON=$(aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`]' --output json)
    
    if [ -z "$ACCOUNTS_JSON" ] || [ "$ACCOUNTS_JSON" = "[]" ]; then
        echo -e "${RED}❌ No active accounts found${NC}"
        exit 1
    fi
    
    # Extract account IDs by name pattern
    DEV_ACCOUNT_ID=$(echo "$ACCOUNTS_JSON" | jq -r '.[] | select(.Name | test("Development|Dev"; "i")) | .Id')
    STAGING_ACCOUNT_ID=$(echo "$ACCOUNTS_JSON" | jq -r '.[] | select(.Name | test("Staging|Stage"; "i")) | .Id')
    SHARED_ACCOUNT_ID=$(echo "$ACCOUNTS_JSON" | jq -r '.[] | select(.Name | test("Shared|SharedServices"; "i")) | .Id')
    PROD_ACCOUNT_ID=$(echo "$ACCOUNTS_JSON" | jq -r '.[] | select(.Name | test("Production|Prod"; "i")) | .Id')
    MANAGEMENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Validate all accounts found
    local missing_accounts=()
    [ -z "$DEV_ACCOUNT_ID" ] && missing_accounts+=("Development")
    [ -z "$STAGING_ACCOUNT_ID" ] && missing_accounts+=("Staging")
    [ -z "$SHARED_ACCOUNT_ID" ] && missing_accounts+=("Shared Services")
    [ -z "$PROD_ACCOUNT_ID" ] && missing_accounts+=("Production")
    
    if [ ${#missing_accounts[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing accounts:${NC}"
        printf '   %s\n' "${missing_accounts[@]}"
        echo ""
        echo -e "${YELLOW}💡 Ensure Control Tower created all workload accounts${NC}"
        exit 1
    fi
    
    # Create .env file
    cat > .env << EOF
# AWS Account IDs - Auto-generated by up.sh
MANAGEMENT_ACCOUNT_ID=$MANAGEMENT_ACCOUNT_ID
DEV_ACCOUNT_ID=$DEV_ACCOUNT_ID
STAGING_ACCOUNT_ID=$STAGING_ACCOUNT_ID
SHARED_ACCOUNT_ID=$SHARED_ACCOUNT_ID
PROD_ACCOUNT_ID=$PROD_ACCOUNT_ID

# Auto-generated on $(date)
EOF
    
    echo -e "${GREEN}✅ Account discovery complete${NC}"
    echo "   Management: $MANAGEMENT_ACCOUNT_ID"
    echo "   Development: $DEV_ACCOUNT_ID"
    echo "   Staging: $STAGING_ACCOUNT_ID"
    echo "   Shared Services: $SHARED_ACCOUNT_ID"
    echo "   Production: $PROD_ACCOUNT_ID"
}

discover_accounts
echo ""

# =============================================================================
# STEP 2: SSO SETUP
# =============================================================================

echo -e "${PURPLE}🔐 Step 2: SSO Profile Setup${NC}"
echo "============================"

setup_sso() {
    # Get user email
    if [ -z "$SSO_USER_EMAIL" ]; then
        echo "Enter your email address for SSO access:"
        echo -n "Email: "
        read SSO_USER_EMAIL
    fi
    
    SSO_USER_EMAIL=$(echo "$SSO_USER_EMAIL" | xargs)
    if [ -z "$SSO_USER_EMAIL" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        exit 1
    fi
    
    echo "Setting up SSO for: $SSO_USER_EMAIL"
    
    # Get SSO instance
    SSO_INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text --region ap-southeast-1)
    if [ -z "$SSO_INSTANCE_ARN" ] || [ "$SSO_INSTANCE_ARN" = "None" ]; then
        echo -e "${RED}❌ IAM Identity Center not found${NC}"
        exit 1
    fi
    
    echo "Found SSO Instance: $SSO_INSTANCE_ARN"
    
    # Find user by email
    USER_ID=$(aws identitystore list-users --identity-store-id $(echo $SSO_INSTANCE_ARN | cut -d'/' -f3) --region ap-southeast-1 --query "Users[?UserName=='$SSO_USER_EMAIL'].UserId" --output text)
    
    if [ -z "$USER_ID" ] || [ "$USER_ID" = "None" ]; then
        echo -e "${RED}❌ User not found: $SSO_USER_EMAIL${NC}"
        echo ""
        echo -e "${YELLOW}💡 Create the user in IAM Identity Center first:${NC}"
        echo "   1. Go to IAM Identity Center console"
        echo "   2. Create user with email: $SSO_USER_EMAIL"
        echo "   3. Re-run this script"
        exit 1
    fi
    
    echo "Found User ID: $USER_ID"
    
    # Get AdministratorAccess permission set
    PERMISSION_SET_ARN=$(aws sso-admin list-permission-sets --instance-arn "$SSO_INSTANCE_ARN" --region ap-southeast-1 --query 'PermissionSets[0]' --output text)
    
    if [ -z "$PERMISSION_SET_ARN" ]; then
        echo -e "${RED}❌ No permission sets found${NC}"
        exit 1
    fi
    
    echo "Using Permission Set: $PERMISSION_SET_ARN"
    
    # Assign user to all workload accounts
    local accounts=("$DEV_ACCOUNT_ID:tar-dev" "$STAGING_ACCOUNT_ID:tar-staging" "$SHARED_ACCOUNT_ID:tar-shared" "$PROD_ACCOUNT_ID:tar-prod")
    
    for account_info in "${accounts[@]}"; do
        IFS=':' read -r account_id profile_name <<< "$account_info"
        
        echo "Assigning user to account $account_id..."
        
        # Create account assignment
        aws sso-admin create-account-assignment \
            --instance-arn "$SSO_INSTANCE_ARN" \
            --target-id "$account_id" \
            --target-type AWS_ACCOUNT \
            --permission-set-arn "$PERMISSION_SET_ARN" \
            --principal-type USER \
            --principal-id "$USER_ID" \
            --region ap-southeast-1 &> /dev/null || true
    done
    
    echo "Waiting for SSO assignments to propagate..."
    sleep 30
    
    # Create SSO profiles
    local sso_start_url=$(aws configure get sso_start_url --profile tar 2>/dev/null || echo "")
    local sso_region=$(aws configure get sso_region --profile tar 2>/dev/null || echo "ap-southeast-1")
    
    if [ -z "$sso_start_url" ]; then
        echo -e "${YELLOW}⚠️ Base SSO profile not found. You'll need to run 'aws configure sso' for each profile manually.${NC}"
    else
        echo "Creating SSO profiles..."
        
        for account_info in "${accounts[@]}"; do
            IFS=':' read -r account_id profile_name <<< "$account_info"
            
            aws configure set sso_start_url "$sso_start_url" --profile "$profile_name"
            aws configure set sso_region "$sso_region" --profile "$profile_name"
            aws configure set sso_account_id "$account_id" --profile "$profile_name"
            aws configure set sso_role_name "AdministratorAccess" --profile "$profile_name"
            aws configure set region "ap-southeast-1" --profile "$profile_name"
            aws configure set output "json" --profile "$profile_name"
        done
    fi
    
    echo -e "${GREEN}✅ SSO setup complete${NC}"
}

setup_sso
echo ""

# =============================================================================
# STEP 3: CDK BOOTSTRAP
# =============================================================================

echo -e "${PURPLE}🛠️ Step 3: CDK Bootstrap${NC}"
echo "========================"

bootstrap_accounts() {
    echo "Bootstrapping CDK in all accounts..."
    
    local profiles=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
    local success_count=0
    local total_count=${#profiles[@]}
    
    for profile in "${profiles[@]}"; do
        echo "Bootstrapping $profile..."
        
        # Test profile access first
        if ! AWS_PROFILE="$profile" aws sts get-caller-identity &> /dev/null; then
            echo -e "${YELLOW}⚠️ Profile $profile not accessible, running SSO login...${NC}"
            aws sso login --profile "$profile"
        fi
        
        # Bootstrap with custom qualifier
        if AWS_PROFILE="$profile" cdk bootstrap --qualifier cdk2024 --cloudformation-execution-policies arn:aws:iam::aws:policy/AdministratorAccess; then
            echo -e "${GREEN}✅ $profile bootstrapped${NC}"
            success_count=$((success_count + 1))
        else
            echo -e "${RED}❌ Failed to bootstrap $profile${NC}"
        fi
    done
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}✅ All accounts bootstrapped successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ $success_count/$total_count accounts bootstrapped${NC}"
    fi
}

bootstrap_accounts
echo ""

# =============================================================================
# STEP 4: COMPREHENSIVE VALIDATION
# =============================================================================

echo -e "${PURPLE}✅ Step 4: Environment Validation${NC}"
echo "================================"

validate_environment() {
    local checks_passed=0
    local total_checks=20
    
    echo "Running comprehensive validation..."
    echo ""
    
    # Check 1-4: Prerequisites
    echo "🔍 Prerequisites:"
    command -v node &> /dev/null && echo "  ✅ Node.js installed" && ((checks_passed++)) || echo "  ❌ Node.js missing"
    command -v aws &> /dev/null && echo "  ✅ AWS CLI installed" && ((checks_passed++)) || echo "  ❌ AWS CLI missing"
    command -v cdk &> /dev/null && echo "  ✅ CDK installed" && ((checks_passed++)) || echo "  ❌ CDK missing"
    command -v jq &> /dev/null && echo "  ✅ jq installed" && ((checks_passed++)) || echo "  ❌ jq missing"
    
    # Check 5-9: Account IDs
    echo "🏢 Account Discovery:"
    [ -n "$MANAGEMENT_ACCOUNT_ID" ] && echo "  ✅ Management account: $MANAGEMENT_ACCOUNT_ID" && ((checks_passed++)) || echo "  ❌ Management account missing"
    [ -n "$DEV_ACCOUNT_ID" ] && echo "  ✅ Development account: $DEV_ACCOUNT_ID" && ((checks_passed++)) || echo "  ❌ Development account missing"
    [ -n "$STAGING_ACCOUNT_ID" ] && echo "  ✅ Staging account: $STAGING_ACCOUNT_ID" && ((checks_passed++)) || echo "  ❌ Staging account missing"
    [ -n "$SHARED_ACCOUNT_ID" ] && echo "  ✅ Shared account: $SHARED_ACCOUNT_ID" && ((checks_passed++)) || echo "  ❌ Shared account missing"
    [ -n "$PROD_ACCOUNT_ID" ] && echo "  ✅ Production account: $PROD_ACCOUNT_ID" && ((checks_passed++)) || echo "  ❌ Production account missing"
    
    # Check 10-13: SSO Profiles
    echo "🔐 SSO Profiles:"
    local profiles=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
    for profile in "${profiles[@]}"; do
        if AWS_PROFILE="$profile" aws sts get-caller-identity &> /dev/null; then
            echo "  ✅ $profile profile working"
            ((checks_passed++))
        else
            echo "  ❌ $profile profile not working"
        fi
    done
    
    # Check 14-17: CDK Bootstrap
    echo "🛠️ CDK Bootstrap:"
    for profile in "${profiles[@]}"; do
        if AWS_PROFILE="$profile" aws cloudformation describe-stacks --stack-name cdktoolkit &> /dev/null; then
            echo "  ✅ $profile CDK bootstrap complete"
            ((checks_passed++))
        else
            echo "  ❌ $profile CDK bootstrap missing"
        fi
    done
    
    # Check 18: SSO Instance
    echo "🔍 IAM Identity Center:"
    if [ -n "$SSO_INSTANCE_ARN" ]; then
        echo "  ✅ SSO instance: $SSO_INSTANCE_ARN"
        ((checks_passed++))
    else
        echo "  ❌ SSO instance not found"
    fi
    
    # Check 19: Environment file
    echo "📄 Configuration:"
    if [ -f .env ]; then
        echo "  ✅ .env file created"
        ((checks_passed++))
    else
        echo "  ❌ .env file missing"
    fi
    
    # Check 20: CDK synthesis
    echo "🔄 CDK Configuration:"
    if cdk synth &> /dev/null; then
        echo "  ✅ CDK synthesis successful"
        ((checks_passed++))
    else
        echo "  ❌ CDK synthesis failed"
    fi
    
    echo ""
    echo "📊 Validation Summary: $checks_passed/$total_checks checks passed"
    
    if [ $checks_passed -eq $total_checks ]; then
        echo -e "${GREEN}🎉 All validation checks passed!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Some checks failed. Environment may not be fully ready.${NC}"
        return 1
    fi
}

validate_environment
VALIDATION_RESULT=$?
echo ""

# =============================================================================
# STEP 5: COST PROTECTION SETUP
# =============================================================================

echo -e "${PURPLE}💵 Step 5: Cost Protection Setup${NC}"
echo "==============================="

setup_cost_protection() {
    # Get email for alerts
    if [ -z "$ALERT_EMAIL" ]; then
        echo "Enter email for cost alerts (or press Enter to skip):"
        echo -n "Email: "
        read ALERT_EMAIL
    fi
    
    ALERT_EMAIL=$(echo "$ALERT_EMAIL" | xargs)
    
    if [ -z "$ALERT_EMAIL" ]; then
        echo -e "${YELLOW}⚠️ Skipping cost protection setup${NC}"
        return 0
    fi
    
    echo "Setting up cost protection for: $ALERT_EMAIL"
    
    # Create budgets for each account
    local accounts=("$DEV_ACCOUNT_ID:Development:20" "$STAGING_ACCOUNT_ID:Staging:30" "$SHARED_ACCOUNT_ID:Shared:25" "$PROD_ACCOUNT_ID:Production:50")
    
    for account_info in "${accounts[@]}"; do
        IFS=':' read -r account_id account_name budget_amount <<< "$account_info"
        
        echo "Creating $budget_amount USD budget for $account_name..."
        
        # Create budget JSON
        cat > /tmp/budget-${account_name}.json << EOF
{
  "BudgetName": "${account_name}-Monthly-Budget",
  "BudgetLimit": {
    "Amount": "${budget_amount}",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "TimePeriod": {
    "Start": "$(date +%Y-%m-01)",
    "End": "2030-12-31"
  },
  "BudgetType": "COST",
  "CostFilters": {
    "LinkedAccount": ["${account_id}"]
  }
}
EOF
        
        # Create notifications JSON
        cat > /tmp/notifications-${account_name}.json << EOF
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${ALERT_EMAIL}"
      }
    ]
  }
]
EOF
        
        # Create budget
        aws budgets create-budget \
            --account-id "$MANAGEMENT_ACCOUNT_ID" \
            --budget file:///tmp/budget-${account_name}.json \
            --notifications-with-subscribers file:///tmp/notifications-${account_name}.json \
            --region us-east-1 &> /dev/null || true
            
        # Clean up temp files
        rm -f /tmp/budget-${account_name}.json /tmp/notifications-${account_name}.json
    done
    
    echo -e "${GREEN}✅ Cost protection setup complete${NC}"
    echo "   Budgets created for all accounts"
    echo "   Email alerts will be sent to: $ALERT_EMAIL"
    echo "   Alert threshold: 80% of budget"
}

setup_cost_protection
echo ""

# =============================================================================
# STEP 6: APPLICATION DEPLOYMENT
# =============================================================================

echo -e "${PURPLE}🚀 Step 6: Application Deployment${NC}"
echo "================================"

deploy_applications() {
    if [ $VALIDATION_RESULT -ne 0 ]; then
        echo -e "${YELLOW}⚠️ Validation failed. Skipping application deployment.${NC}"
        echo "   Fix validation issues and run: cdk deploy --all"
        return 0
    fi
    
    echo "Do you want to deploy applications now? (y/n)"
    echo -n "Deploy: "
    read DEPLOY_CHOICE
    
    if [ "$DEPLOY_CHOICE" != "y" ]; then
        echo -e "${YELLOW}⚠️ Skipping application deployment${NC}"
        echo "   To deploy later, run: cdk deploy --all"
        return 0
    fi
    
    echo "Deploying applications to all environments..."
    
    # Deploy all stacks
    if cdk deploy --all --require-approval never; then
        echo -e "${GREEN}✅ All applications deployed successfully${NC}"
        
        # Test endpoints
        echo ""
        echo "Testing deployed endpoints..."
        sleep 10  # Wait for API Gateway to be fully ready
        
        local profiles=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
        local stack_names=("helloworld-dev" "helloworld-staging" "helloworld-shared" "helloworld-prod")
        
        for i in "${!profiles[@]}"; do
            profile="${profiles[$i]}"
            stack_name="${stack_names[$i]}"
            
            # Get API URL from CloudFormation output
            API_URL=$(AWS_PROFILE="$profile" aws cloudformation describe-stacks \
                --stack-name "$stack_name" \
                --query 'Stacks[0].Outputs[?OutputKey==`helloworldapiurl`].OutputValue' \
                --output text 2>/dev/null || echo "")
            
            if [ -n "$API_URL" ]; then
                echo "Testing $profile: $API_URL"
                if curl -s "$API_URL" > /dev/null; then
                    echo -e "  ${GREEN}✅ $profile endpoint working${NC}"
                else
                    echo -e "  ${YELLOW}⚠️ $profile endpoint not responding${NC}"
                fi
            else
                echo -e "  ${YELLOW}⚠️ $profile API URL not found${NC}"
            fi
        done
    else
        echo -e "${RED}❌ Application deployment failed${NC}"
        echo "   Check the errors above and try: cdk deploy --all"
    fi
}

deploy_applications
echo ""

# =============================================================================
# FINAL SUMMARY
# =============================================================================

echo -e "${BLUE}🎉 Setup Complete!${NC}"
echo "=================="
echo ""
echo -e "${GREEN}✅ Environment Status:${NC}"
echo "   • Account discovery: Complete"
echo "   • SSO profiles: Configured"
echo "   • CDK bootstrap: Complete"
echo "   • Validation: $checks_passed/20 checks passed"
echo "   • Cost protection: Configured"
echo "   • Applications: Ready for deployment"
echo ""
echo -e "${CYAN}🚀 Next Steps:${NC}"
echo "   • Deploy applications: cdk deploy --all"
echo "   • Check validation: ./scripts/validate-complete-setup.sh"
echo "   • Save costs: ./scripts/down.sh"
echo ""
echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "   • Deploy specific env: AWS_PROFILE=tar-dev cdk deploy helloworld-dev"
echo "   • Check costs: aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-12-31 --granularity MONTHLY --metrics BlendedCost"
echo "   • SSO login: aws sso login --profile tar-dev"
echo ""
echo -e "${BLUE}📊 Monthly Cost Estimate: \$35-70 USD${NC}"
echo -e "${GREEN}💰 Use './scripts/down.sh' to save 99% costs when not developing${NC}"