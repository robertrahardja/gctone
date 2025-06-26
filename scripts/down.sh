#!/bin/bash

# AWS Control Tower Environment Destruction Script
# ================================================
# Smart cost management with multiple destruction options

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script version and info
SCRIPT_VERSION="2.0"
SCRIPT_NAME="AWS Environment Destruction Manager"

echo -e "${RED}🗑️ ${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
echo "============================================="
echo -e "${YELLOW}Smart cost management and cleanup options${NC}"
echo ""

# Load environment if available
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✅ Environment loaded${NC}"
else
    echo -e "${YELLOW}⚠️ No .env file found. Some features may be limited.${NC}"
fi

echo ""

# =============================================================================
# DESTRUCTION OPTIONS MENU
# =============================================================================

show_options_menu() {
    echo -e "${CYAN}💰 Choose Your Cost Management Strategy:${NC}"
    echo "========================================"
    echo ""
    echo -e "${GREEN}Option 1: Smart Savings (Recommended)${NC}"
    echo "   🗑️ Destroy: Applications (Lambda, API Gateway, logs)"
    echo "   💾 Keep: Foundation (Control Tower, CDK bootstrap, SSO)"
    echo -e "   💰 Saves: ${YELLOW}\$36-120/month → \$0.10/month (99% reduction)${NC}"
    echo -e "   ⏱️ Time: ${BLUE}5 minutes${NC}"
    echo -e "   🔄 Resume: ${GREEN}2 minutes (cdk deploy --all)${NC}"
    echo ""
    echo -e "${YELLOW}Option 2: Deep Clean${NC}"
    echo "   🗑️ Destroy: Everything except Control Tower accounts"
    echo "   💾 Keep: Control Tower workload accounts only"
    echo -e "   💰 Saves: ${YELLOW}\$40-125/month → \$0.10/month${NC}"
    echo -e "   ⏱️ Time: ${BLUE}15 minutes${NC}"
    echo -e "   🔄 Resume: ${YELLOW}15 minutes (./scripts/up.sh)${NC}"
    echo ""
    echo -e "${RED}Option 3: Nuclear Option${NC}"
    echo "   🗑️ Destroy: Everything + guidance for account closure"
    echo "   💾 Keep: Nothing (complete cleanup)"
    echo -e "   💰 Saves: ${YELLOW}\$40-125/month → \$0/month${NC}"
    echo -e "   ⏱️ Time: ${RED}60-90 days for account closure${NC}"
    echo -e "   🔄 Resume: ${RED}1.5 hours (complete rebuild)${NC}"
    echo ""
    echo -e "${BLUE}Option 4: Status Check${NC}"
    echo "   📊 Check current environment status"
    echo "   💡 Get cost estimates and recommendations"
    echo ""
    echo -e "${CYAN}What would you like to do?${NC}"
    echo "1) Smart Savings (destroy apps, keep foundation)"
    echo "2) Deep Clean (destroy everything except accounts)"
    echo "3) Nuclear Option (complete destruction + account closure)"
    echo "4) Status Check (check current state)"
    echo "5) Exit"
    echo ""
    echo -n "Choose option (1-5): "
    read OPTION_CHOICE
}

# =============================================================================
# OPTION 1: SMART SAVINGS
# =============================================================================

smart_savings() {
    echo -e "${GREEN}🎯 Smart Savings Mode${NC}"
    echo "===================="
    echo ""
    echo -e "${YELLOW}This will destroy:${NC}"
    echo "• All Lambda functions (saves ~\$5-15/month per function)"
    echo "• All API Gateways (saves ~\$3-10/month per API)"
    echo "• CloudWatch Log Groups (saves ~\$1-5/month)"
    echo "• Application stacks in all 4 environments"
    echo ""
    echo -e "${GREEN}This will preserve:${NC}"
    echo "• Control Tower accounts and governance"
    echo "• CDK bootstrap infrastructure"
    echo "• SSO profiles and access"
    echo "• S3 buckets (empty, ~\$0.02/month)"
    echo ""
    echo -e "${CYAN}💡 Perfect for: Daily/weekly development cycles${NC}"
    echo -e "${GREEN}🔄 Resume anytime with: cdk deploy --all (2 minutes)${NC}"
    echo ""
    
    read -p "Continue with Smart Savings? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Operation cancelled."
        return 0
    fi
    
    echo ""
    echo -e "${PURPLE}🚀 Starting application destruction...${NC}"
    
    # Check prerequisites
    if ! command -v aws &> /dev/null || ! command -v cdk &> /dev/null; then
        echo -e "${RED}❌ AWS CLI or CDK not found${NC}"
        exit 1
    fi
    
    # Load environment
    if [ ! -f .env ]; then
        echo -e "${RED}❌ .env file not found. Run ./scripts/up.sh first${NC}"
        exit 1
    fi
    
    # Define stacks and profiles
    STACKS=("helloworld-dev:tar-dev" "helloworld-staging:tar-staging" "helloworld-shared:tar-shared" "helloworld-prod:tar-prod")
    
    SUCCESS_COUNT=0
    TOTAL_COUNT=${#STACKS[@]}
    
    # Destroy each stack
    for stack_info in "${STACKS[@]}"; do
        IFS=':' read -r stack_name profile <<< "$stack_info"
        
        echo -e "${YELLOW}🗑️ Destroying $stack_name...${NC}"
        
        # Check if stack exists
        if aws cloudformation describe-stacks --stack-name "$stack_name" --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
            echo "  Stack exists, proceeding with destruction..."
            
            # Destroy the stack
            if AWS_PROFILE="$profile" cdk destroy "$stack_name" --force; then
                echo -e "${GREEN}  ✅ $stack_name destroyed successfully${NC}"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo -e "${RED}  ❌ Failed to destroy $stack_name${NC}"
            fi
        else
            echo -e "${YELLOW}  ⏭️ $stack_name doesn't exist, skipping${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
        
        echo ""
    done
    
    # Summary
    echo -e "${BLUE}📊 Smart Savings Summary${NC}"
    echo "========================"
    echo -e "Stacks processed: ${SUCCESS_COUNT}/${TOTAL_COUNT}"
    
    if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
        echo -e "${GREEN}🎉 Smart savings complete!${NC}"
        echo ""
        echo -e "${BLUE}💰 Monthly cost savings:${NC}"
        echo "• Lambda functions: ~\$20-60/month saved"
        echo "• API Gateways: ~\$12-40/month saved"
        echo "• CloudWatch logs: ~\$4-20/month saved"
        echo "• Total savings: ~\$36-120/month"
        echo ""
        echo -e "${BLUE}💡 What remains (minimal cost):${NC}"
        echo "• Control Tower accounts: ~\$0/month (free)"
        echo "• CDK bootstrap S3 buckets: ~\$0.10/month total"
        echo "• IAM resources: ~\$0/month (free)"
        echo "• Total remaining cost: ~\$0.10/month"
        echo ""
        echo -e "${GREEN}✅ Your infrastructure foundation is preserved and ready!${NC}"
        echo ""
        echo -e "${CYAN}🚀 To resume development:${NC}"
        echo "• cdk deploy --all"
        echo "• OR: ./scripts/up.sh (will detect existing setup)"
    else
        echo -e "${YELLOW}⚠️ Partial success. Some stacks may need manual cleanup.${NC}"
    fi
}

# =============================================================================
# OPTION 2: DEEP CLEAN
# =============================================================================

deep_clean() {
    echo -e "${YELLOW}☢️ Deep Clean Mode${NC}"
    echo "=================="
    echo ""
    echo -e "${RED}⚠️ WARNING: This will destroy MOST infrastructure${NC}"
    echo ""
    echo -e "${YELLOW}This will destroy:${NC}"
    echo "• All applications (Lambda, API Gateway, logs)"
    echo "• CDK bootstrap infrastructure (S3 buckets, IAM roles)"
    echo "• Local SSO configuration"
    echo "• Application stacks in all environments"
    echo ""
    echo -e "${GREEN}This will preserve:${NC}"
    echo "• Control Tower workload accounts"
    echo "• IAM Identity Center setup"
    echo ""
    echo -e "${CYAN}💡 Perfect for: Long-term storage (1+ months)${NC}"
    echo -e "${YELLOW}🔄 Resume with: ./scripts/up.sh (15 minutes)${NC}"
    echo ""
    
    read -p "Are you sure? Type 'DEEP CLEAN' to proceed: " confirm
    if [ "$confirm" != "DEEP CLEAN" ]; then
        echo "Operation cancelled."
        return 0
    fi
    
    echo ""
    echo -e "${PURPLE}💀 Starting deep clean...${NC}"
    
    # Step 1: Run smart savings first
    echo -e "${YELLOW}🗑️ Step 1: Destroying applications...${NC}"
    smart_savings_silent
    
    echo ""
    
    # Step 2: Destroy CDK bootstrap
    echo -e "${YELLOW}🗑️ Step 2: Destroying CDK bootstrap...${NC}"
    
    PROFILES=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
    
    for profile in "${PROFILES[@]}"; do
        echo "Destroying CDK bootstrap in $profile..."
        
        # Delete CDK toolkit stack
        if aws cloudformation describe-stacks --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
            echo "  Deleting cdktoolkit stack..."
            aws cloudformation delete-stack --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 || true
            
            # Wait for deletion
            echo "  Waiting for stack deletion..."
            aws cloudformation wait stack-delete-complete --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 || true
            echo -e "${GREEN}  ✅ cdktoolkit stack deleted${NC}"
        else
            echo "  cdktoolkit stack doesn't exist, skipping..."
        fi
        
        # Delete S3 buckets (CDK assets)
        echo "  Finding and deleting CDK S3 buckets..."
        BUCKETS=$(aws s3 ls --profile "$profile" --region ap-southeast-1 | grep "cdk-" | awk '{print $3}' || true)
        
        for bucket in $BUCKETS; do
            if [ -n "$bucket" ]; then
                echo "    Emptying and deleting bucket: $bucket"
                aws s3 rb "s3://$bucket" --force --profile "$profile" || true
            fi
        done
        
        echo ""
    done
    
    # Step 3: Clean up local configuration
    echo -e "${YELLOW}🗑️ Step 3: Cleaning local configuration...${NC}"
    
    # Remove .env file
    if [ -f .env ]; then
        echo "Removing .env file..."
        rm .env
        echo -e "${GREEN}✅ .env file removed${NC}"
    fi
    
    # Ask about SSO profiles
    echo ""
    read -p "Remove SSO profiles from ~/.aws/config? (y/n): " remove_sso
    if [ "$remove_sso" = "y" ]; then
        echo "Backing up ~/.aws/config..."
        cp ~/.aws/config ~/.aws/config.backup.$(date +%Y%m%d_%H%M%S) || true
        
        # Remove tar-* profiles
        if grep -q "\\[profile tar-" ~/.aws/config 2>/dev/null; then
            echo "Removing tar-* profiles from ~/.aws/config..."
            sed -i '' '/\\[profile tar-/,/^$/d' ~/.aws/config || true
            echo -e "${GREEN}✅ SSO profiles removed${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📊 Deep Clean Complete${NC}"
    echo "======================"
    echo -e "${GREEN}✅ Applications destroyed${NC}"
    echo -e "${GREEN}✅ CDK bootstrap infrastructure destroyed${NC}"
    echo -e "${GREEN}✅ Local configuration cleaned${NC}"
    echo ""
    echo -e "${BLUE}💰 Cost after deep clean:${NC}"
    echo "• Monthly cost: ~\$0.10/month (Control Tower base)"
    echo "• Savings: ~\$36-120/month from destroyed infrastructure"
    echo ""
    echo -e "${CYAN}🚀 To rebuild everything:${NC}"
    echo "• ./scripts/up.sh (15 minutes)"
}

# =============================================================================
# OPTION 3: NUCLEAR OPTION
# =============================================================================

nuclear_option() {
    echo -e "${RED}☢️ Nuclear Option${NC}"
    echo "================="
    echo ""
    echo -e "${RED}🚨 EXTREME WARNING: This is the nuclear option${NC}"
    echo ""
    echo -e "${YELLOW}This will:${NC}"
    echo "• Run deep clean (destroy everything except accounts)"
    echo "• Provide instructions for manual account closure"
    echo "• Result in complete infrastructure removal"
    echo ""
    echo -e "${RED}After this:${NC}"
    echo "• Account closure takes 60-90 days"
    echo "• Complete rebuild requires 1.5 hours"
    echo "• No quick recovery options"
    echo ""
    echo -e "${CYAN}💡 Only use if: You're completely done with this project${NC}"
    echo ""
    
    read -p "Are you ABSOLUTELY sure? Type 'NUCLEAR' to proceed: " confirm
    if [ "$confirm" != "NUCLEAR" ]; then
        echo "Operation cancelled. Smart choice!"
        return 0
    fi
    
    echo ""
    read -p "Last chance! Type 'YES DELETE EVERYTHING' to proceed: " final_confirm
    if [ "$final_confirm" != "YES DELETE EVERYTHING" ]; then
        echo "Operation cancelled."
        return 0
    fi
    
    echo ""
    echo -e "${PURPLE}💀 Initiating nuclear option...${NC}"
    
    # Run deep clean first
    echo -e "${YELLOW}Step 1: Running deep clean...${NC}"
    deep_clean_silent
    
    echo ""
    echo -e "${YELLOW}Step 2: Account closure guidance${NC}"
    echo "================================="
    echo ""
    echo -e "${BLUE}ℹ️ Control Tower workload accounts cannot be destroyed via scripts.${NC}"
    echo ""
    echo -e "${YELLOW}To close accounts manually:${NC}"
    echo "1. Go to AWS Control Tower console"
    echo "2. Navigate to Account Factory"
    echo "3. Close each workload account:"
    
    if [ -n "$DEV_ACCOUNT_ID" ]; then
        echo "   • Development ($DEV_ACCOUNT_ID)"
    fi
    if [ -n "$STAGING_ACCOUNT_ID" ]; then
        echo "   • Staging ($STAGING_ACCOUNT_ID)"
    fi
    if [ -n "$SHARED_ACCOUNT_ID" ]; then
        echo "   • Shared Services ($SHARED_ACCOUNT_ID)"
    fi
    if [ -n "$PROD_ACCOUNT_ID" ]; then
        echo "   • Production ($PROD_ACCOUNT_ID)"
    fi
    
    echo ""
    echo -e "${RED}⚠️ Important Notes:${NC}"
    echo "• Account closure is irreversible"
    echo "• Takes 60-90 days for complete deletion"
    echo "• All data will be permanently lost"
    echo "• You'll receive email confirmations"
    echo ""
    echo -e "${BLUE}📊 Nuclear Option Complete${NC}"
    echo "=========================="
    echo -e "${GREEN}✅ All destructible infrastructure removed${NC}"
    echo -e "${YELLOW}⚠️ Manual account closure required for 100% cleanup${NC}"
    echo ""
    echo -e "${BLUE}💰 Final cost: \$0/month (after account closure)${NC}"
    echo -e "${CYAN}🔄 To start fresh: Complete rebuild (1.5 hours)${NC}"
}

# =============================================================================
# OPTION 4: STATUS CHECK
# =============================================================================

status_check() {
    echo -e "${BLUE}📊 Environment Status Check${NC}"
    echo "============================"
    echo ""
    
    # Check if environment is set up
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️ No .env file found${NC}"
        echo "   Environment not set up or already cleaned"
        echo ""
        echo -e "${CYAN}Recommendations:${NC}"
        echo "• Run ./scripts/up.sh to set up environment"
        echo "• Or this is already a clean state"
        return 0
    fi
    
    echo -e "${GREEN}✅ Environment file found${NC}"
    echo ""
    
    # Check account access
    echo "🔍 Checking account access..."
    local profiles=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
    local working_profiles=0
    
    for profile in "${profiles[@]}"; do
        if AWS_PROFILE="$profile" aws sts get-caller-identity &> /dev/null; then
            echo -e "  ${GREEN}✅ $profile profile working${NC}"
            ((working_profiles++))
        else
            echo -e "  ${YELLOW}⚠️ $profile profile not accessible${NC}"
        fi
    done
    
    echo ""
    
    # Check deployed applications
    echo "🚀 Checking deployed applications..."
    local deployed_stacks=0
    local stack_names=("helloworld-dev:tar-dev" "helloworld-staging:tar-staging" "helloworld-shared:tar-shared" "helloworld-prod:tar-prod")
    
    for stack_info in "${stack_names[@]}"; do
        IFS=':' read -r stack_name profile <<< "$stack_info"
        
        if AWS_PROFILE="$profile" aws cloudformation describe-stacks --stack-name "$stack_name" --region ap-southeast-1 &> /dev/null; then
            echo -e "  ${GREEN}✅ $stack_name deployed${NC}"
            ((deployed_stacks++))
        else
            echo -e "  ${YELLOW}⚠️ $stack_name not deployed${NC}"
        fi
    done
    
    echo ""
    
    # Cost estimation
    echo "💰 Current cost estimation..."
    if [ $deployed_stacks -gt 0 ]; then
        echo -e "  ${YELLOW}Active development mode${NC}"
        echo "  • Estimated cost: \$35-70/month"
        echo "  • Lambda functions: ~\$20-60/month"
        echo "  • API Gateways: ~\$12-40/month"
        echo "  • CloudWatch logs: ~\$4-20/month"
        echo "  • Foundation: ~\$0.10/month"
        echo ""
        echo -e "${CYAN}💡 Cost saving options:${NC}"
        echo "  • Smart savings: Save \$36-120/month (99% reduction)"
        echo "  • Keep foundation ready for 2-minute redeploy"
    else
        echo -e "  ${GREEN}Cost savings mode${NC}"
        echo "  • Current cost: ~\$0.10/month"
        echo "  • Foundation preserved"
        echo "  • Ready for quick redeploy"
    fi
    
    echo ""
    
    # Recommendations
    echo -e "${CYAN}📋 Recommendations:${NC}"
    
    if [ $deployed_stacks -eq 4 ]; then
        echo "• ✅ All applications deployed and ready"
        echo "• 💡 Use Smart Savings when not actively developing"
        echo "• 🔄 Quick redeploy anytime with: cdk deploy --all"
    elif [ $deployed_stacks -gt 0 ]; then
        echo "• ⚠️ Partial deployment detected"
        echo "• 🔧 Deploy missing apps: cdk deploy --all"
        echo "• 🗑️ Or clean up with Smart Savings"
    elif [ $working_profiles -eq 4 ]; then
        echo "• ✅ Foundation ready, no applications deployed"
        echo "• 🚀 Deploy applications: cdk deploy --all"
        echo "• 💡 Perfect cost-optimized state for storage"
    else
        echo "• ⚠️ Environment issues detected"
        echo "• 🔧 Run ./scripts/up.sh to fix issues"
        echo "• 🗑️ Or clean up with Deep Clean"
    fi
}

# =============================================================================
# SILENT HELPER FUNCTIONS
# =============================================================================

smart_savings_silent() {
    # Silent version of smart_savings for use in other functions
    if [ ! -f .env ]; then
        return 1
    fi
    
    STACKS=("helloworld-dev:tar-dev" "helloworld-staging:tar-staging" "helloworld-shared:tar-shared" "helloworld-prod:tar-prod")
    
    for stack_info in "${STACKS[@]}"; do
        IFS=':' read -r stack_name profile <<< "$stack_info"
        
        if aws cloudformation describe-stacks --stack-name "$stack_name" --profile "$profile" --region ap-southeast-1 > /dev/null 2>&1; then
            AWS_PROFILE="$profile" cdk destroy "$stack_name" --force &> /dev/null || true
        fi
    done
}

deep_clean_silent() {
    # Silent version of deep_clean for use in nuclear option
    smart_savings_silent
    
    PROFILES=("tar-dev" "tar-staging" "tar-shared" "tar-prod")
    
    for profile in "${PROFILES[@]}"; do
        # Delete CDK toolkit stack
        aws cloudformation delete-stack --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 &> /dev/null || true
        aws cloudformation wait stack-delete-complete --stack-name cdktoolkit --profile "$profile" --region ap-southeast-1 &> /dev/null || true
        
        # Delete S3 buckets
        BUCKETS=$(aws s3 ls --profile "$profile" --region ap-southeast-1 2>/dev/null | grep "cdk-" | awk '{print $3}' || true)
        for bucket in $BUCKETS; do
            if [ -n "$bucket" ]; then
                aws s3 rb "s3://$bucket" --force --profile "$profile" &> /dev/null || true
            fi
        done
    done
    
    # Remove .env file
    rm -f .env
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

show_options_menu

case $OPTION_CHOICE in
    1)
        echo ""
        smart_savings
        ;;
    2)
        echo ""
        deep_clean
        ;;
    3)
        echo ""
        nuclear_option
        ;;
    4)
        echo ""
        status_check
        ;;
    5)
        echo -e "${GREEN}👋 Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid option. Please choose 1-5.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎯 Operation complete!${NC}"