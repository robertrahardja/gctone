#!/bin/bash

# Create Per-Account Billing Alerts
# Creates CloudWatch billing alarms for each AWS account with $10 SGD thresholds

set -e

echo "🚨 Creating Per-Account Billing Alerts"
echo "====================================="
echo ""
echo "This script will create \$10 SGD billing alerts for each account:"
echo "🔸 Development: \$10 SGD"
echo "🔸 Staging: \$10 SGD" 
echo "🔸 Shared Services: \$10 SGD"
echo "🔸 Production: \$10 SGD"
echo ""

# Load account IDs
if [ ! -f .env ]; then
    echo "❌ .env file not found. Run ./scripts/get-account-ids.sh first"
    exit 1
fi

source .env

# Get email for billing alerts
if [ ! -z "$ALERT_EMAIL" ]; then
    echo "📧 Using email from environment variable: $ALERT_EMAIL"
else
    echo "📧 Please enter your email address for billing alerts:"
    echo "   (This will receive all billing notifications)"
    echo -n "Email: "
    read ALERT_EMAIL
fi

# Trim whitespace and validate
ALERT_EMAIL=$(echo "$ALERT_EMAIL" | xargs)
if [ -z "$ALERT_EMAIL" ]; then
    echo "❌ Email address required for billing alerts"
    echo "💡 Tip: You can also set the email as an environment variable:"
    echo "   export ALERT_EMAIL=your@email.com"
    echo "   ./scripts/create-per-account-alerts.sh"
    exit 1
fi

echo ""
echo "📧 Using email: $ALERT_EMAIL"
echo ""

# Function to create billing alert for an account
create_account_alert() {
    local account_name="$1"
    local account_id="$2"
    local threshold="$3"
    
    echo "Setting up billing alert for $account_name ($account_id)..."
    
    # Create SNS topic for this account
    local topic_name="billing-alerts-$(echo "$account_name" | tr '[:upper:]' '[:lower:]')"
    local topic_arn
    
    echo "  📞 Creating SNS topic: $topic_name"
    topic_arn=$(aws sns create-topic --name "$topic_name" --query 'TopicArn' --output text 2>/dev/null || \
               aws sns list-topics --query "Topics[?contains(TopicArn, '$topic_name')].TopicArn" --output text | head -1)
    
    if [ -z "$topic_arn" ]; then
        echo "  ❌ Failed to create or find SNS topic"
        return 1
    fi
    
    echo "  ✅ SNS topic: $topic_arn"
    
    # Subscribe email to topic
    echo "  📧 Adding email subscription..."
    aws sns subscribe \
        --topic-arn "$topic_arn" \
        --protocol email \
        --notification-endpoint "$ALERT_EMAIL" >/dev/null 2>&1 || echo "  ⚠️  Email may already be subscribed"
    
    # Create billing alarm
    local alarm_name="${account_name}-Monthly-Spend-Alert"
    echo "  ⏰ Creating CloudWatch alarm: $alarm_name"
    
    aws cloudwatch put-metric-alarm \
        --alarm-name "$alarm_name" \
        --alarm-description "Billing alert for $account_name account - \$${threshold} SGD threshold" \
        --metric-name EstimatedCharges \
        --namespace AWS/Billing \
        --statistic Maximum \
        --period 21600 \
        --evaluation-periods 1 \
        --threshold "$threshold" \
        --comparison-operator GreaterThanThreshold \
        --alarm-actions "$topic_arn" \
        --dimensions Name=Currency,Value=SGD Name=LinkedAccount,Value="$account_id" \
        --treat-missing-data notBreaching
    
    echo "  ✅ Billing alert created: $account_name (\$${threshold} SGD)"
    echo ""
}

# Create alerts for each account
echo "🔧 Creating per-account billing alerts..."
echo ""

if [ ! -z "$dev_account_id" ]; then
    create_account_alert "Development" "$dev_account_id" "10"
fi

if [ ! -z "$staging_account_id" ]; then
    create_account_alert "Staging" "$staging_account_id" "10"
fi

if [ ! -z "$shared_account_id" ]; then
    create_account_alert "SharedServices" "$shared_account_id" "10"
fi

if [ ! -z "$prod_account_id" ]; then
    create_account_alert "Production" "$prod_account_id" "10"
fi

# Create management account alert too
if [ ! -z "$management_account_id" ]; then
    create_account_alert "Management" "$management_account_id" "10"
fi

echo "🎉 Per-Account Billing Alerts Created Successfully!"
echo "================================================="
echo ""
echo "📧 IMPORTANT: Check your email ($ALERT_EMAIL) and confirm all SNS subscriptions"
echo ""
echo "📊 What you now have:"
echo "✅ Billing alerts for all accounts at \$10 SGD threshold"
echo "✅ Separate SNS topics for organized notifications"
echo "✅ Email notifications for all cost overruns"
echo ""
echo "💡 NEXT STEPS:"
echo "1. Confirm all email subscriptions (check your inbox)"
echo "2. Consider running ./scripts/create-budgets.sh for additional budget controls"
echo "3. Monitor costs at: https://console.aws.amazon.com/billing/"
echo ""
echo "🔍 All billing alarms are now active and monitoring your accounts!"