#!/bin/bash

# Automated AWS SSO Profile Setup Script
# =====================================
# This script automates the creation of AWS CLI SSO profiles for each
# workload account in a Control Tower multi-account setup. It eliminates
# the manual process of running 'aws configure sso' for each environment.

# Exit on any error
set -e

# Load environment variables containing account IDs
source .env

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Automated AWS SSO Profile Setup${NC}"
echo "===================================="
echo ""

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "Please install AWS CLI first: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
    exit 1
fi

# Check if we have the base SSO profile
if ! aws configure list-profiles | grep -q "^tar$"; then
    echo -e "${RED}❌ Base SSO profile 'tar' not found${NC}"
    echo "Please set up your base SSO profile first:"
    echo "  aws configure sso --profile tar"
    exit 1
fi

# Function to get SSO session information from existing profile
get_sso_info() {
    local profile=$1
    
    # Extract SSO session name
    local sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null || echo "")
    
    if [ -n "$sso_session" ]; then
        # Get SSO URL and region from session configuration
        # Parse from config file since AWS CLI doesn't expose session details directly
        local config_file="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
        local sso_start_url=$(grep -A 10 "\[sso-session $sso_session\]" "$config_file" | grep "sso_start_url" | cut -d'=' -f2 | tr -d ' ')
        local sso_region=$(grep -A 10 "\[sso-session $sso_session\]" "$config_file" | grep "sso_region" | cut -d'=' -f2 | tr -d ' ')
        
        echo "$sso_session|$sso_start_url|$sso_region"
    else
        # Fallback: get from profile directly (legacy format)
        local sso_start_url=$(aws configure get sso_start_url --profile "$profile" 2>/dev/null || echo "")
        local sso_region=$(aws configure get sso_region --profile "$profile" 2>/dev/null || echo "")
        
        echo "|$sso_start_url|$sso_region"
    fi
}

# Get SSO configuration from base profile
echo -e "${YELLOW}🔍 Detecting SSO configuration from base profile...${NC}"
SSO_INFO=$(get_sso_info "tar")
IFS='|' read -r SSO_SESSION SSO_START_URL SSO_REGION <<< "$SSO_INFO"

if [ -z "$SSO_START_URL" ]; then
    echo -e "${RED}❌ Could not detect SSO configuration from base profile${NC}"
    echo "Please ensure your 'tar' profile is properly configured with SSO"
    exit 1
fi

echo -e "${GREEN}✅ SSO Configuration detected:${NC}"
echo "  Start URL: $SSO_START_URL"
echo "  Region: $SSO_REGION"
if [ -n "$SSO_SESSION" ]; then
    echo "  Session: $SSO_SESSION"
fi
echo ""

# Function to create SSO profile programmatically
create_sso_profile() {
    local profile_name=$1
    local account_id=$2
    local role_name=$3
    local environment=$4
    
    echo -e "${YELLOW}📝 Creating profile: $profile_name${NC}"
    
    # Set SSO configuration
    aws configure set sso_start_url "$SSO_START_URL" --profile "$profile_name"
    aws configure set sso_region "$SSO_REGION" --profile "$profile_name"
    aws configure set sso_account_id "$account_id" --profile "$profile_name"
    aws configure set sso_role_name "$role_name" --profile "$profile_name"
    aws configure set region "${aws_default_region:-us-east-1}" --profile "$profile_name"
    aws configure set output "json" --profile "$profile_name"
    
    # Set SSO session if available
    if [ -n "$SSO_SESSION" ]; then
        aws configure set sso_session "$SSO_SESSION" --profile "$profile_name"
    fi
    
    echo -e "${GREEN}  ✅ Profile $profile_name created${NC}"
}

# Function to test profile access
test_profile() {
    local profile_name=$1
    
    echo -e "${YELLOW}🧪 Testing profile: $profile_name${NC}"
    
    # Try to get caller identity (this will prompt for SSO login if needed)
    if aws sts get-caller-identity --profile "$profile_name" --output table > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Profile $profile_name is working${NC}"
        return 0
    else
        echo -e "${RED}  ❌ Profile $profile_name failed authentication${NC}"
        echo "  💡 You may need to run: aws sso login --profile $profile_name"
        return 1
    fi
}

# Create profiles for each environment
echo -e "${BLUE}🏗️  Creating SSO profiles for all environments...${NC}"
echo ""

# Default role name (can be customized)
ROLE_NAME="${SSO_ROLE_NAME:-AWSAdministratorAccess}"

# Create each profile using simple arrays
PROFILES="tar-dev tar-staging tar-shared tar-prod"
ACCOUNT_IDS="$dev_account_id $staging_account_id $shared_account_id $prod_account_id"
ENV_NAMES="Development Staging SharedServices Production"

# Convert to arrays
set -- $PROFILES
PROFILES_ARRAY=("$@")
set -- $ACCOUNT_IDS  
ACCOUNT_IDS_ARRAY=("$@")
set -- $ENV_NAMES
ENV_NAMES_ARRAY=("$@")

# Create each profile
for i in $(seq 0 $((${#PROFILES_ARRAY[@]} - 1))); do
    profile_env="${PROFILES_ARRAY[$i]}"
    account_id="${ACCOUNT_IDS_ARRAY[$i]}"
    env_name="${ENV_NAMES_ARRAY[$i]}"
    
    if [ -z "$account_id" ]; then
        echo -e "${RED}❌ Account ID not found for $profile_env${NC}"
        echo "   Please ensure .env file contains all account IDs"
        continue
    fi
    
    # Skip if profile already exists
    if aws configure list-profiles | grep -q "^${profile_env}$"; then
        echo -e "${YELLOW}⏭️  Profile $profile_env already exists, skipping...${NC}"
        continue
    fi
    
    create_sso_profile "$profile_env" "$account_id" "$ROLE_NAME" "$env_name"
done

echo ""
echo -e "${BLUE}🔐 Testing SSO authentication...${NC}"
echo ""

# Test each profile
SUCCESS_COUNT=0
TOTAL_COUNT=0

for i in $(seq 0 $((${#PROFILES_ARRAY[@]} - 1))); do
    profile_env="${PROFILES_ARRAY[$i]}"
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    if test_profile "$profile_env"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
done

echo ""
echo -e "${BLUE}📊 Setup Summary${NC}"
echo "================="
echo -e "Profiles created: ${GREEN}$TOTAL_COUNT${NC}"
echo -e "Profiles working: ${GREEN}$SUCCESS_COUNT${NC}"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}🎉 All SSO profiles set up successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Some profiles need authentication${NC}"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "1. Run SSO login for any failed profiles:"
    for i in $(seq 0 $((${#PROFILES_ARRAY[@]} - 1))); do
        profile_env="${PROFILES_ARRAY[$i]}"
        echo "   aws sso login --profile $profile_env"
    done
fi

echo ""
echo -e "${BLUE}🚀 Ready for CDK bootstrap and deployment!${NC}"
echo ""
echo "Next commands to run:"
echo "  1. ./scripts/bootstrap-accounts.sh    # Bootstrap CDK in all accounts"
echo "  2. ./scripts/deploy-applications.sh   # Deploy applications to all environments"
echo ""

# Create a summary file for reference
cat > sso-profiles-summary.md << EOF
# AWS SSO Profiles Summary

Generated on: $(date)

## Created Profiles

| Profile | Account ID | Environment | Role |
|---------|------------|-------------|------|
$(for i in $(seq 0 $((${#PROFILES_ARRAY[@]} - 1))); do
    profile_env="${PROFILES_ARRAY[$i]}"
    account_id="${ACCOUNT_IDS_ARRAY[$i]}"
    env_name="${ENV_NAMES_ARRAY[$i]}"
    echo "| $profile_env | $account_id | $env_name | $ROLE_NAME |"
done)

## Usage

### CDK Bootstrap
\`\`\`bash
AWS_PROFILE=tar ./scripts/bootstrap-accounts.sh
\`\`\`

### Individual Account Access
\`\`\`bash
aws sts get-caller-identity --profile tar-dev
aws sts get-caller-identity --profile tar-staging
aws sts get-caller-identity --profile tar-shared
aws sts get-caller-identity --profile tar-prod
\`\`\`

### SSO Login (if needed)
\`\`\`bash
aws sso login --profile tar-dev
aws sso login --profile tar-staging
aws sso login --profile tar-shared
aws sso login --profile tar-prod
\`\`\`

## Configuration Files
- AWS Config: ~/.aws/config
- Credentials: ~/.aws/credentials (not used with SSO)
EOF

echo -e "${GREEN}📄 Summary saved to: sso-profiles-summary.md${NC}"