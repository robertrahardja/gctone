#!/bin/bash

# Script to sync account emails from AWS Organizations to accounts.ts config
# This script fetches the actual emails from your AWS organization and automatically updates the config

set -e

echo "🔄 Syncing account emails from AWS Organizations..."

# Check if accounts.ts exists
ACCOUNTS_FILE="lib/config/accounts.ts"
if [ ! -f "$ACCOUNTS_FILE" ]; then
    echo "❌ File not found: $ACCOUNTS_FILE"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Create backup
BACKUP_FILE="${ACCOUNTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$ACCOUNTS_FILE" "$BACKUP_FILE"
echo "📋 Created backup: $BACKUP_FILE"

# Function to get account email by name
get_account_email() {
    local account_name="$1"
    aws organizations list-accounts \
        --query "Accounts[?Name=='$account_name' && Status=='ACTIVE'].Email" \
        --output text 2>/dev/null
}

# Function to get management account email
get_management_email() {
    # Try to find management account by checking for the current account
    local current_account=$(aws sts get-caller-identity --query Account --output text)
    aws organizations list-accounts \
        --query "Accounts[?Id=='$current_account'].Email" \
        --output text 2>/dev/null
}

echo "📧 Fetching account emails..."

# Get emails for each account
MANAGEMENT_EMAIL=$(get_management_email)
DEV_EMAIL=$(get_account_email "Development")
STAGING_EMAIL=$(get_account_email "Staging") 
SHARED_EMAIL=$(get_account_email "Shared Services")
PROD_EMAIL=$(get_account_email "Production")
AUDIT_EMAIL=$(get_account_email "Audit")
LOG_ARCHIVE_EMAIL=$(get_account_email "Log Archive")

echo "✅ Found emails:"
echo "  Management: $MANAGEMENT_EMAIL"
echo "  Development: $DEV_EMAIL"
echo "  Staging: $STAGING_EMAIL"
echo "  Shared Services: $SHARED_EMAIL"
echo "  Production: $PROD_EMAIL"
echo "  Audit: $AUDIT_EMAIL"
echo "  Log Archive: $LOG_ARCHIVE_EMAIL"

# Function to update email in accounts.ts
update_email() {
    local account_key="$1"
    local new_email="$2"
    local file="$3"
    
    if [ -n "$new_email" ] && [ "$new_email" != "None" ]; then
        # Update workload account emails (in the accounts object)
        if [[ "$account_key" =~ ^(dev|staging|shared|prod)$ ]]; then
            sed -i.tmp "s|email: \"[^\"]*\", // update with ./scripts/sync-account-emails.sh|email: \"$new_email\", // update with ./scripts/sync-account-emails.sh|g" "$file"
            # Also update any old format
            sed -i.tmp "s|email: \"[^\"]*\",.*//.*$account_key|email: \"$new_email\", // update with ./scripts/sync-account-emails.sh|g" "$file"
        fi
        
        # Update core account emails (in the core_accounts object)
        if [[ "$account_key" =~ ^(management|audit|logarchive)$ ]]; then
            sed -i.tmp "s|$account_key: \"[^\"]*\", // update with ./scripts/sync-account-emails.sh|$account_key: \"$new_email\", // update with ./scripts/sync-account-emails.sh|g" "$file"
            # Also update any old format
            sed -i.tmp "s|$account_key: \"[^\"]*\",.*// .*|$account_key: \"$new_email\", // update with ./scripts/sync-account-emails.sh|g" "$file"
        fi
        
        echo "✅ Updated $account_key: $new_email"
    else
        echo "⚠️  Skipping $account_key: email not found"
    fi
}

echo ""
echo "🔧 Updating accounts.ts..."

# Update workload account emails by finding and replacing the specific patterns
if [ -n "$DEV_EMAIL" ] && [ "$DEV_EMAIL" != "None" ]; then
    # Find the dev account block and update its email
    sed -i.tmp "/dev: {/,/},/ s|email: \"[^\"]*\",.*|email: \"$DEV_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated dev account: $DEV_EMAIL"
fi

if [ -n "$STAGING_EMAIL" ] && [ "$STAGING_EMAIL" != "None" ]; then
    # Find the staging account block and update its email
    sed -i.tmp "/staging: {/,/},/ s|email: \"[^\"]*\",.*|email: \"$STAGING_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated staging account: $STAGING_EMAIL"
fi

if [ -n "$SHARED_EMAIL" ] && [ "$SHARED_EMAIL" != "None" ]; then
    # Find the shared account block and update its email
    sed -i.tmp "/shared: {/,/},/ s|email: \"[^\"]*\",.*|email: \"$SHARED_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated shared account: $SHARED_EMAIL"
fi

if [ -n "$PROD_EMAIL" ] && [ "$PROD_EMAIL" != "None" ]; then
    # Find the prod account block and update its email
    sed -i.tmp "/prod: {/,/},/ s|email: \"[^\"]*\",.*|email: \"$PROD_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated prod account: $PROD_EMAIL"
fi

# Update core account emails
if [ -n "$MANAGEMENT_EMAIL" ] && [ "$MANAGEMENT_EMAIL" != "None" ]; then
    sed -i.tmp "s|management: \"[^\"]*\",.*|management: \"$MANAGEMENT_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated management account: $MANAGEMENT_EMAIL"
fi

if [ -n "$AUDIT_EMAIL" ] && [ "$AUDIT_EMAIL" != "None" ]; then
    sed -i.tmp "s|audit: \"[^\"]*\",.*|audit: \"$AUDIT_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated audit account: $AUDIT_EMAIL"
fi

if [ -n "$LOG_ARCHIVE_EMAIL" ] && [ "$LOG_ARCHIVE_EMAIL" != "None" ]; then
    sed -i.tmp "s|logarchive: \"[^\"]*\",.*|logarchive: \"$LOG_ARCHIVE_EMAIL\", // update with ./scripts/sync-account-emails.sh|" "$ACCOUNTS_FILE"
    echo "✅ Updated log archive account: $LOG_ARCHIVE_EMAIL"
fi

# Clean up temporary files
rm -f "${ACCOUNTS_FILE}.tmp"

echo ""
echo "🎉 Email sync complete!"
echo ""
echo "📋 Summary:"
echo "  - Backup created: $BACKUP_FILE"
echo "  - Configuration updated: $ACCOUNTS_FILE"
echo ""
echo "🔍 Verify the changes:"
echo "  git diff $ACCOUNTS_FILE"
echo ""
echo "📧 Current account emails:"
aws organizations list-accounts --query "Accounts[?Status=='ACTIVE'].[Name,Email]" --output table

echo ""
echo "💡 If you need to revert changes:"
echo "  cp $BACKUP_FILE $ACCOUNTS_FILE"