#!/bin/bash

# Complete Environment Setup Script
# =================================
# This script automates the entire setup process for a new Control Tower project
# from account discovery to CDK bootstrap. Perfect for greenfield projects.
#
# What this script does:
# 1. Gets all Control Tower account IDs 
# 2. Sets up automated SSO user assignments
# 3. Creates SSO profiles for all accounts
# 4. Waits for SSO access to become ready
# 5. Bootstraps CDK in all accounts
# 6. Validates the complete setup
#
# Usage: ./scripts/setup-complete-environment.sh [--skip-sso] [--skip-bootstrap]

set -e

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Parse command line arguments
SKIP_SSO=false
SKIP_BOOTSTRAP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-sso)
            SKIP_SSO=true
            shift
            ;;
        --skip-bootstrap)
            SKIP_BOOTSTRAP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--skip-sso] [--skip-bootstrap]"
            echo ""
            echo "Options:"
            echo "  --skip-sso        Skip SSO setup (if already done)"
            echo "  --skip-bootstrap  Skip CDK bootstrap (if already done)"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Complete Control Tower Environment Setup${NC}"
echo "============================================="
echo ""
echo "This script will set up your entire Control Tower environment:"
echo "• Discover all account IDs"
echo "• Set up SSO user assignments"  
echo "• Create SSO profiles"
echo "• Bootstrap CDK in all accounts"
echo "• Validate the complete setup"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is not installed (required for JSON processing)${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

if ! command -v cdk &> /dev/null; then
    echo -e "${RED}❌ AWS CDK is not installed${NC}"
    echo "Install with: npm install -g aws-cdk"
    exit 1
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ AWS CLI is not configured or no valid credentials${NC}"
    echo "Please ensure you're logged in with management account access"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Get account IDs
echo -e "${PURPLE}📋 Step 1: Discovering Control Tower accounts...${NC}"
if [ ! -f .env ] || ! grep -q "dev_account_id" .env 2>/dev/null; then
    echo "Running account discovery..."
    ./scripts/get-account-ids.sh
else
    echo "✅ Account IDs already discovered (.env file exists)"
    source .env
    echo "  • Development: $dev_account_id"
    echo "  • Staging: $staging_account_id"
    echo "  • Shared Services: $shared_account_id"
    echo "  • Production: $prod_account_id"
    echo "  • Management: $management_account_id"
fi
echo ""

# Step 2: Set up SSO (if not skipped)
if [ "$SKIP_SSO" = true ]; then
    echo -e "${PURPLE}📋 Step 2: Skipping SSO setup (--skip-sso flag used)${NC}"
else
    echo -e "${PURPLE}📋 Step 2: Setting up SSO user assignments...${NC}"
    
    # Check if we need to set up users first
    if [ -z "$BASE_EMAIL" ]; then
        echo -e "${YELLOW}📧 BASE_EMAIL not set. Please enter your email for user management:${NC}"
        read -p "Enter your base email address: " BASE_EMAIL
        if [ -z "$BASE_EMAIL" ]; then
            echo -e "${RED}❌ No email provided${NC}"
            exit 1
        fi
        echo "BASE_EMAIL=\"$BASE_EMAIL\"" >> .env
        source .env
    fi
    
    echo "Using base email: $BASE_EMAIL"
    
    # Set up automated SSO profiles
    echo "Setting up SSO profiles..."
    ./scripts/setup-automated-sso.sh
    
    # Assign current user to all accounts (based on our learnings)
    echo "Assigning current user to all accounts..."
    ./scripts/assign-sso-permissions-fast.sh
    
    # Wait for SSO access to be ready
    echo "Waiting for SSO access to become ready..."
    ./scripts/wait-for-sso-access.sh
fi
echo ""

# Step 3: Bootstrap CDK (if not skipped)
if [ "$SKIP_BOOTSTRAP" = true ]; then
    echo -e "${PURPLE}📋 Step 3: Skipping CDK bootstrap (--skip-bootstrap flag used)${NC}"
else
    echo -e "${PURPLE}📋 Step 3: Bootstrapping CDK in all accounts...${NC}"
    ./scripts/bootstrap-accounts.sh
fi
echo ""

# Step 4: Final validation
echo -e "${PURPLE}📋 Step 4: Validating complete setup...${NC}"

# Check SSO profiles
echo "Testing SSO profiles..."
PROFILES=("tar-dev:Development" "tar-staging:Staging" "tar-shared:Shared" "tar-prod:Production")
SSO_SUCCESS=0
for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile name <<< "$profile_info"
    if aws sts get-caller-identity --profile "$profile" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ $name ($profile) - Working${NC}"
        SSO_SUCCESS=$((SSO_SUCCESS + 1))
    else
        echo -e "${RED}  ❌ $name ($profile) - Not working${NC}"
    fi
done

# Check CDK bootstrap
echo "Checking CDK bootstrap status..."
CDK_SUCCESS=0
for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile name <<< "$profile_info"
    if aws cloudformation describe-stacks --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ $name CDK toolkit - Ready${NC}"
        CDK_SUCCESS=$((CDK_SUCCESS + 1))
    else
        echo -e "${RED}  ❌ $name CDK toolkit - Not found${NC}"
    fi
done

echo ""

# Final summary
echo -e "${BLUE}📊 Setup Summary${NC}"
echo "================"
echo -e "SSO Profiles Working: ${GREEN}$SSO_SUCCESS/4${NC}"
echo -e "CDK Bootstraps Complete: ${GREEN}$CDK_SUCCESS/4${NC}"

if [ $SSO_SUCCESS -eq 4 ] && [ $CDK_SUCCESS -eq 4 ]; then
    echo ""
    echo -e "${GREEN}🎉 COMPLETE SUCCESS! Your environment is fully ready!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Deploy applications: ./scripts/deploy-applications.sh"
    echo "2. Set up monitoring: ./scripts/create-budgets.sh"
    echo "3. Validate deployments: ./scripts/validate-deployments.sh"
    echo ""
    echo -e "${BLUE}💡 Quick Test Commands:${NC}"
    echo "• Test dev access: aws sts get-caller-identity --profile tar-dev"
    echo "• Test staging access: aws sts get-caller-identity --profile tar-staging"
    echo "• Check all profiles: ./scripts/check-sso-status.sh"
elif [ $SSO_SUCCESS -eq 4 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  SSO is working but CDK bootstrap incomplete${NC}"
    echo "Run: ./scripts/bootstrap-accounts.sh"
elif [ $CDK_SUCCESS -eq 4 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  CDK is ready but SSO profiles have issues${NC}" 
    echo "Run: ./scripts/check-sso-status.sh for diagnosis"
else
    echo ""
    echo -e "${RED}❌ Setup incomplete. Please review the errors above${NC}"
    echo ""
    echo -e "${BLUE}💡 Troubleshooting:${NC}"
    echo "• Check SSO status: ./scripts/check-sso-status.sh"
    echo "• Re-run setup: $0"
    echo "• Manual SSO assignment: ./scripts/assign-sso-permissions.sh"
fi

echo ""
echo -e "${BLUE}📝 Important Files Created:${NC}"
echo "• .env - Contains all account IDs"
echo "• ~/.aws/config - Contains SSO profiles (tar-dev, tar-staging, etc.)"
echo ""
echo -e "${BLUE}⏰ Total Setup Time: Usually 10-15 minutes for a complete greenfield setup${NC}"