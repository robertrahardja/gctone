#!/bin/bash

# Quick SSO Status Checker
# ========================
# Run this anytime to check current status

source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Current SSO Status Check${NC}"
echo "============================"
echo ""

# 1. Check provisioning operations
echo -e "${YELLOW}🔍 Checking active provisioning operations:${NC}"
PROVISIONING=$(aws sso-admin list-permission-set-provisioning-status \
    --region ap-southeast-1 \
    --instance-arn "arn:aws:sso:::instance/ssoins-82104f8dce4b745c" \
    --output json 2>/dev/null)

if [ $? -eq 0 ]; then
    ACTIVE_COUNT=$(echo "$PROVISIONING" | jq '.PermissionSetProvisioningStatus | length')
    if [ "$ACTIVE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}  ⏳ $ACTIVE_COUNT operations in progress${NC}"
    else
        echo -e "${GREEN}  ✅ No active provisioning operations${NC}"
    fi
else
    echo -e "${RED}  ❌ Cannot check provisioning status${NC}"
fi

echo ""

# 2. Test each profile
echo -e "${YELLOW}🧪 Testing SSO profiles:${NC}"
PROFILES=("tar-dev:Development:803133978889" "tar-staging:Staging:521744733620" "tar-shared:Shared:216665870694" "tar-prod:Production:668427974646")

SUCCESS_COUNT=0
TOTAL_COUNT=${#PROFILES[@]}

for profile_info in "${PROFILES[@]}"; do
    IFS=':' read -r profile name account_id <<< "$profile_info"
    
    RESULT=$(aws sts get-caller-identity --profile "$profile" 2>&1)
    if echo "$RESULT" | grep -q "arn:aws"; then
        echo -e "${GREEN}  ✅ $name ($profile) - Working${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    elif echo "$RESULT" | grep -q "ForbiddenException"; then
        echo -e "${YELLOW}  ⏳ $name ($profile) - Still provisioning${NC}"
    else
        echo -e "${RED}  ❌ $name ($profile) - Error: $(echo "$RESULT" | head -1)${NC}"
    fi
done

echo ""

# 3. Summary
echo -e "${BLUE}📈 Summary:${NC}"
echo "Working profiles: $SUCCESS_COUNT/$TOTAL_COUNT"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}🎉 All profiles ready! You can proceed with:${NC}"
    echo "   ./scripts/bootstrap-accounts.sh"
elif [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⏳ Partially ready. Some profiles still provisioning.${NC}"
    echo "   Wait a few more minutes and run this script again."
else
    echo -e "${RED}❌ No profiles working yet. AWS still provisioning.${NC}"
    echo "   Try again in 5-10 minutes."
fi

echo ""

# 4. Estimated time remaining
if [ $SUCCESS_COUNT -lt $TOTAL_COUNT ]; then
    echo -e "${BLUE}⏰ Typical AWS provisioning times:${NC}"
    echo "  • Account assignments: 2-5 minutes"
    echo "  • Role creation: 5-10 minutes" 
    echo "  • Session propagation: 10-15 minutes"
    echo "  • Total: Usually ready within 15 minutes"
fi