#!/bin/bash

# SSO Access Waiting Script
# =========================
# Continuously checks when SSO profiles become ready
# Retries every 30 seconds with intelligent backoff

set -e
source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}⏰ Waiting for SSO Access to Become Ready${NC}"
echo "=========================================="
echo ""

# Test profiles to check
PROFILES=("tar-dev:Development" "tar-staging:Staging" "tar-shared:Shared" "tar-prod:Production")

# Function to test a single profile
test_profile() {
    local profile="$1"
    local name="$2"
    
    local result=$(aws sts get-caller-identity --profile "$profile" 2>&1)
    if echo "$result" | grep -q "ForbiddenException"; then
        return 1  # Still failing
    elif echo "$result" | grep -q "arn:aws"; then
        return 0  # Success
    else
        return 2  # Other error
    fi
}

# Function to check all profiles
check_all_profiles() {
    local success_count=0
    local total_count=${#PROFILES[@]}
    
    echo -e "${YELLOW}🧪 Testing all profiles...${NC}"
    
    for profile_info in "${PROFILES[@]}"; do
        IFS=':' read -r profile name <<< "$profile_info"
        
        if test_profile "$profile" "$name"; then
            echo -e "${GREEN}  ✅ $name ($profile) - Working${NC}"
            success_count=$((success_count + 1))
        else
            echo -e "${RED}  ❌ $name ($profile) - Not ready${NC}"
        fi
    done
    
    echo ""
    echo -e "${BLUE}📊 Status: $success_count/$total_count profiles working${NC}"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        return 0  # All working
    else
        return 1  # Some still failing
    fi
}

# Function to check provisioning status via API
check_provisioning_status() {
    echo -e "${YELLOW}🔍 Checking AWS provisioning status...${NC}"
    
    # Check if there are any active provisioning operations
    local provisioning_status=$(aws sso-admin list-permission-set-provisioning-status \
        --region ap-southeast-1 \
        --instance-arn "arn:aws:sso:::instance/ssoins-82104f8dce4b745c" \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local active_count=$(echo "$provisioning_status" | jq '.PermissionSetProvisioningStatus | length')
        if [ "$active_count" -gt 0 ]; then
            echo -e "${YELLOW}  ⏳ $active_count active provisioning operations${NC}"
            return 1  # Still provisioning
        else
            echo -e "${GREEN}  ✅ No active provisioning operations${NC}"
            return 0  # Provisioning complete
        fi
    else
        echo -e "${YELLOW}  ⚠️  Cannot check provisioning status${NC}"
        return 1
    fi
}

# Main waiting loop
max_attempts=30  # 15 minutes (30 * 30 seconds)
attempt=1
wait_seconds=30

echo -e "${BLUE}🚀 Starting continuous monitoring...${NC}"
echo "Will check every $wait_seconds seconds for up to $((max_attempts * wait_seconds / 60)) minutes"
echo ""

while [ $attempt -le $max_attempts ]; do
    echo -e "${BLUE}📍 Attempt $attempt/$max_attempts ($(date '+%H:%M:%S'))${NC}"
    echo "----------------------------------------"
    
    # Check provisioning status first
    provisioning_ready=false
    if check_provisioning_status; then
        provisioning_ready=true
    fi
    
    echo ""
    
    # Test profiles
    if check_all_profiles; then
        echo -e "${GREEN}🎉 SUCCESS! All SSO profiles are now working!${NC}"
        echo ""
        echo -e "${BLUE}🧪 Final verification:${NC}"
        for profile_info in "${PROFILES[@]}"; do
            IFS=':' read -r profile name <<< "$profile_info"
            account_info=$(aws sts get-caller-identity --profile "$profile" --output json 2>/dev/null)
            if [ $? -eq 0 ]; then
                account_id=$(echo "$account_info" | jq -r '.Account')
                role_arn=$(echo "$account_info" | jq -r '.Arn')
                echo -e "${GREEN}  ✅ $name: Account $account_id${NC}"
                echo -e "${GREEN}     Role: $role_arn${NC}"
            fi
        done
        
        echo ""
        echo -e "${GREEN}🚀 Ready to continue with CDK bootstrap:${NC}"
        echo "   ./scripts/bootstrap-accounts.sh"
        exit 0
    fi
    
    # Calculate next wait time with some intelligence
    if [ $attempt -le 5 ]; then
        wait_seconds=30  # First 5 attempts: every 30 seconds
    elif [ $attempt -le 15 ]; then
        wait_seconds=60  # Next 10 attempts: every minute
    else
        wait_seconds=120 # Final attempts: every 2 minutes
    fi
    
    echo -e "${YELLOW}⏳ Waiting $wait_seconds seconds before next check...${NC}"
    echo ""
    
    sleep $wait_seconds
    attempt=$((attempt + 1))
done

echo -e "${RED}❌ Timeout: SSO profiles still not ready after $((max_attempts * 30 / 60)) minutes${NC}"
echo ""
echo -e "${BLUE}💡 Troubleshooting options:${NC}"
echo "1. Check IAM Identity Center console manually:"
echo "   https://console.aws.amazon.com/singlesignon"
echo ""
echo "2. Try manual assignment:"
echo "   ./scripts/show-manual-steps.sh"
echo ""
echo "3. Contact AWS support if this persists"

exit 1