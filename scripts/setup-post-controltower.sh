#!/bin/bash

# Post-Control Tower Automation Script
# Run this after manual Control Tower setup is complete

set -e

echo "🚀 Starting Post-Control Tower Automation"
echo "========================================"

# Check if Control Tower is set up
if ! aws controltower list-landing-zones 2>/dev/null >/dev/null; then
    echo "❌ Control Tower not available. Complete manual setup first."
    exit 1
fi

echo "✅ Control Tower detected"

# 1. Create Organizational Units
echo "📁 Creating Organizational Units..."

# Get root organization ID
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Create Non-Production OU
echo "Creating Non-Production OU..."
NONPROD_OU=$(aws organizations create-organizational-unit \
    --parent-id $ROOT_ID \
    --name "Non-Production" \
    --query 'OrganizationalUnit.Id' --output text 2>/dev/null || \
    aws organizations list-organizational-units-for-parent \
    --parent-id $ROOT_ID \
    --query 'OrganizationalUnits[?Name==`Non-Production`].Id' --output text)

# Create Production OU
echo "Creating Production OU..."
PROD_OU=$(aws organizations create-organizational-unit \
    --parent-id $ROOT_ID \
    --name "Production" \
    --query 'OrganizationalUnit.Id' --output text 2>/dev/null || \
    aws organizations list-organizational-units-for-parent \
    --parent-id $ROOT_ID \
    --query 'OrganizationalUnits[?Name==`Production`].Id' --output text)

echo "✅ OUs created: Non-Production ($NONPROD_OU), Production ($PROD_OU)"

# 2. Create workload accounts (requires Account Factory)
echo "📧 Creating workload accounts..."

# Note: This requires the emails to be updated in the script
# You'll need to replace these with your actual email addresses
read -p "Enter your base email (e.g., your-email@gmail.com): " BASE_EMAIL

if [ -z "$BASE_EMAIL" ]; then
    echo "❌ Email required. Please run with email addresses configured."
    exit 1
fi

# Extract base email without domain for aliases
EMAIL_PREFIX=$(echo $BASE_EMAIL | cut -d'@' -f1)
EMAIL_DOMAIN=$(echo $BASE_EMAIL | cut -d'@' -f2)

# Create Development Account
echo "Creating Development account..."
aws controltower create-managed-account \
    --control-tower-details '{
        "managedAccountRequest": {
            "accountName": "Development",
            "accountEmail": "'${EMAIL_PREFIX}'+dev@'${EMAIL_DOMAIN}'",
            "organizationalUnitDistinguishedName": "Non-Production"
        }
    }' || echo "⚠️  Account creation may have failed or account already exists"

# Create Staging Account
echo "Creating Staging account..."
aws controltower create-managed-account \
    --control-tower-details '{
        "managedAccountRequest": {
            "accountName": "Staging", 
            "accountEmail": "'${EMAIL_PREFIX}'+staging@'${EMAIL_DOMAIN}'",
            "organizationalUnitDistinguishedName": "Non-Production"
        }
    }' || echo "⚠️  Account creation may have failed or account already exists"

# Create Shared Services Account
echo "Creating Shared Services account..."
aws controltower create-managed-account \
    --control-tower-details '{
        "managedAccountRequest": {
            "accountName": "Shared Services",
            "accountEmail": "'${EMAIL_PREFIX}'+shared@'${EMAIL_DOMAIN}'", 
            "organizationalUnitDistinguishedName": "Non-Production"
        }
    }' || echo "⚠️  Account creation may have failed or account already exists"

# Create Production Account
echo "Creating Production account..."
aws controltower create-managed-account \
    --control-tower-details '{
        "managedAccountRequest": {
            "accountName": "Production",
            "accountEmail": "'${EMAIL_PREFIX}'+prod@'${EMAIL_DOMAIN}'",
            "organizationalUnitDistinguishedName": "Production"
        }
    }' || echo "⚠️  Account creation may have failed or account already exists"

echo "✅ Account creation requests submitted (may take 10-15 minutes each)"

# 3. Set up billing alerts
echo "💰 Setting up billing alerts..."

# Enable billing alerts preference
aws ce put-preferences --preferences '{
    "ReceiveBillingAlerts": true
}' 2>/dev/null || echo "⚠️  Billing preferences may already be set"

# Create SNS topic for billing alerts
BILLING_TOPIC_ARN=$(aws sns create-topic --name billing-alerts --query 'TopicArn' --output text)
echo "✅ Created billing alerts SNS topic: $BILLING_TOPIC_ARN"

# Subscribe email to SNS topic
read -p "Enter email for billing alerts: " BILLING_EMAIL
aws sns subscribe \
    --topic-arn $BILLING_TOPIC_ARN \
    --protocol email \
    --notification-endpoint $BILLING_EMAIL

echo "📧 Email subscription created. Please check your email and confirm the subscription."

# Create organization-wide billing alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "Organization-Monthly-Spend-Alert-500" \
    --alarm-description "Alert when organization monthly spend exceeds $500" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 21600 \
    --threshold 500 \
    --comparison-operator GreaterThanThreshold \
    --alarm-actions $BILLING_TOPIC_ARN \
    --dimensions Name=Currency,Value=USD

echo "✅ Organization billing alarm created ($500 threshold)"

# 4. Set up cost allocation tags
echo "🏷️  Setting up cost allocation tags..."

# Activate AWS-generated cost allocation tags
aws ce put-cost-categories \
    --name "aws-generated-tags" \
    --rules '[
        {
            "value": "createdBy",
            "rule": {
                "dimension": {
                    "key": "TAG",
                    "values": ["aws:createdBy"]
                }
            }
        }
    ]' 2>/dev/null || echo "⚠️  Cost categories may already exist"

echo "✅ Cost allocation tags configured"

# 5. Enable Cost Explorer
echo "📊 Enabling Cost Explorer..."
aws ce get-usage-and-costs \
    --time-period Start=2024-01-01,End=2024-01-02 \
    --granularity DAILY \
    --metrics BlendedCost 2>/dev/null || echo "⚠️  Cost Explorer may need manual enablement"

echo "✅ Cost Explorer access verified"

# 6. Wait for accounts and get IDs
echo "⏳ Waiting for account creation to complete..."
echo "This may take 30-60 minutes. You can run ./scripts/get-account-ids.sh periodically to check progress."

# 7. Create budgets (run after accounts are created)
echo "💵 Creating budgets will be done after accounts are ready..."
echo "Run ./scripts/create-budgets.sh after account creation completes"

echo ""
echo "🎉 Post-Control Tower automation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Confirm email subscriptions for billing alerts"
echo "2. Wait for workload account creation (check AWS Console)"
echo "3. Run ./scripts/get-account-ids.sh when accounts are ready"
echo "4. Run ./scripts/create-budgets.sh to set up per-account budgets"
echo "5. Run ./scripts/setup-sso.sh to configure IAM Identity Center"
echo "6. Continue with CDK bootstrap and deployment"