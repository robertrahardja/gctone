#!/bin/bash

# Manual SSO Assignment Helper
# ============================
# This script shows you the exact manual steps to complete SSO permission assignment
# with your specific account IDs and email addresses.

# Load environment variables containing account IDs
source .env

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Manual SSO Permission Assignment Steps${NC}"
echo "=========================================="
echo ""

if [ -z "$BASE_EMAIL" ]; then
    BASE_EMAIL="testawsrahardja@gmail.com"
fi

echo -e "${YELLOW}🔍 Your Configuration:${NC}"
echo "Base Email: $BASE_EMAIL"
echo "Dev Account: $dev_account_id"
echo "Staging Account: $staging_account_id"
echo "Shared Account: $shared_account_id"
echo "Prod Account: $prod_account_id"
echo ""

echo -e "${BLUE}🚀 Follow these exact steps in the AWS Console:${NC}"
echo ""

echo -e "${GREEN}1. Open IAM Identity Center Console:${NC}"
echo "   https://console.aws.amazon.com/singlesignon"
echo ""

echo -e "${GREEN}2. Create Permission Set (if it doesn't exist):${NC}"
echo "   • Click: Multi-account permissions → Permission sets"
echo "   • Click: Create permission set"
echo "   • Name: AdminAccess"
echo "   • Use predefined permission set: AdministratorAccess"
echo "   • Session duration: 12 hours"
echo "   • Click: Create"
echo ""

echo -e "${GREEN}3. Assign Users to Accounts:${NC}"
echo ""

# Generate the specific assignments
local_part=$(echo "$BASE_EMAIL" | cut -d'@' -f1)
domain=$(echo "$BASE_EMAIL" | cut -d'@' -f2)

echo -e "${YELLOW}📧 Development Account Assignment:${NC}"
echo "   • AWS accounts → Select account: $dev_account_id"
echo "   • Click: Assign users or groups"
echo "   • Select user: ${local_part}+dev@${domain}"
echo "   • Click: Next"
echo "   • Select permission set: AdminAccess"
echo "   • Click: Next → Submit"
echo ""

echo -e "${YELLOW}📧 Staging Account Assignment:${NC}"
echo "   • AWS accounts → Select account: $staging_account_id"
echo "   • Click: Assign users or groups"
echo "   • Select user: ${local_part}+staging@${domain}"
echo "   • Click: Next"
echo "   • Select permission set: AdminAccess"
echo "   • Click: Next → Submit"
echo ""

echo -e "${YELLOW}📧 Shared Services Account Assignment:${NC}"
echo "   • AWS accounts → Select account: $shared_account_id"
echo "   • Click: Assign users or groups"
echo "   • Select user: ${local_part}+shared@${domain}"
echo "   • Click: Next"
echo "   • Select permission set: AdminAccess"
echo "   • Click: Next → Submit"
echo ""

echo -e "${YELLOW}📧 Production Account Assignment:${NC}"
echo "   • AWS accounts → Select account: $prod_account_id"
echo "   • Click: Assign users or groups"
echo "   • Select user: ${local_part}+prod@${domain}"
echo "   • Click: Next"
echo "   • Select permission set: AdminAccess"
echo "   • Click: Next → Submit"
echo ""

echo -e "${GREEN}4. Wait for provisioning (2-3 minutes per assignment)${NC}"
echo ""

echo -e "${GREEN}5. Test your profiles:${NC}"
echo "   aws sts get-caller-identity --profile tar-dev"
echo "   aws sts get-caller-identity --profile tar-staging"
echo "   aws sts get-caller-identity --profile tar-shared"
echo "   aws sts get-caller-identity --profile tar-prod"
echo ""

echo -e "${GREEN}6. Once all profiles work, continue with:${NC}"
echo "   ./scripts/bootstrap-accounts.sh"
echo ""

echo -e "${BLUE}💡 Pro tip:${NC} Keep this terminal open and follow the steps above in your browser."
echo "This should take about 5-10 minutes total."