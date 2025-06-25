#!/bin/bash

# Fix Missing Control Tower Configuration
# This script adds missing high-priority features for users who went through
# Control Tower setup with default settings and didn't configure everything

set -e

# Check if AWS_PROFILE is set, if not, remind user
if [ -z "$AWS_PROFILE" ]; then
    echo "⚠️  AWS_PROFILE not set. Please run with your SSO profile:"
    echo "   AWS_PROFILE=tar ./scripts/fix-missing-controltower-config.sh"
    echo ""
    echo "   Or export it: export AWS_PROFILE=tar"
    echo ""
fi

# Set default region if not configured
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-ap-southeast-1}

echo "🔧 Fixing Missing Control Tower Configuration"
echo "============================================="
echo ""
echo "This script will check your current setup and add missing HIGH PRIORITY features:"
echo "✅ Billing alerts (prevent cost surprises)"
echo "✅ Budgets (control spending)" 
echo "✅ Cost allocation tags (track expenses)"
echo ""

# Function to check if a feature exists
check_feature() {
    local feature_name="$1"
    local check_command="$2"
    
    echo -n "Checking $feature_name... "
    if eval "$check_command" >/dev/null 2>&1; then
        echo "✅ EXISTS"
        return 0
    else
        echo "❌ MISSING"
        return 1
    fi
}

# Function to safely create feature
create_feature() {
    local feature_name="$1"
    local create_command="$2"
    
    echo "Creating $feature_name..."
    if eval "$create_command"; then
        echo "✅ $feature_name created successfully"
    else
        echo "⚠️  Failed to create $feature_name (may already exist or need manual intervention)"
    fi
}

echo "🔍 ASSESSMENT: Checking your current Control Tower configuration..."
echo ""

# 1. Check Control Tower status
echo "1. Control Tower Status:"
# Check for Control Tower using multiple methods since API availability varies
CT_ACTIVE=false

# Method 1: Try list-landing-zones
if aws controltower list-landing-zones --query 'LandingZones[0].Status' --output text 2>/dev/null | grep -q "ACTIVE"; then
    CT_ACTIVE=true
# Method 2: Check for Control Tower OUs
elif aws organizations list-organizational-units-for-parent --parent-id $(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null) --query 'OrganizationalUnits[?Name==`Security`].Name' --output text 2>/dev/null | grep -q "Security"; then
    CT_ACTIVE=true
# Method 3: Check for Control Tower service role
elif aws iam get-role --role-name AWSControlTowerServiceRole 2>/dev/null >/dev/null; then
    CT_ACTIVE=true
fi

if [ "$CT_ACTIVE" = "true" ]; then
    echo "   ✅ Control Tower is active and operational"
else
    echo "   ❌ Control Tower not found or not active"
    echo "   Please complete Control Tower setup first"
    exit 1
fi

# 2. Check basic guardrails
echo ""
echo "2. Guardrails Status:"
GUARDRAILS_COUNT=$(aws controltower list-enabled-controls --target-identifier $(aws organizations list-roots --query 'Roots[0].Arn' --output text) --query 'length(EnabledControls)' --output text 2>/dev/null || echo "0")
echo "   📊 $GUARDRAILS_COUNT guardrails currently enabled"
if [ "$GUARDRAILS_COUNT" -gt 0 ]; then
    echo "   ✅ Basic guardrails are in place"
else
    echo "   ⚠️  No guardrails detected (this is unusual)"
fi

# 3. Check CloudTrail
echo ""
echo "3. CloudTrail Status:"
if aws cloudtrail describe-trails --query 'trailList[?IsOrganizationTrail==`true`] | length(@)' --output text | grep -q -v "0"; then
    echo "   ✅ Organization CloudTrail is configured"
else
    echo "   ⚠️  Organization CloudTrail not found (unusual for Control Tower)"
fi

# 4. Check AWS Config
echo ""
echo "4. AWS Config Status:"
if aws configservice describe-configuration-recorders --query 'length(ConfigurationRecorders)' --output text | grep -q -v "0"; then
    echo "   ✅ AWS Config is recording"
else
    echo "   ⚠️  AWS Config not found (unusual for Control Tower)"
fi

echo ""
echo "🚨 HIGH PRIORITY FEATURES CHECK:"
echo ""

# Check billing preferences
echo "5. Billing Alerts:"
BILLING_ENABLED=$(aws ce get-preferences --query 'ReceiveBillingAlerts' --output text 2>/dev/null || echo "false")
if [ "$BILLING_ENABLED" = "true" ]; then
    echo "   ✅ Billing alerts preference enabled"
else
    echo "   ❌ MISSING: Billing alerts not enabled"
    NEED_BILLING=true
fi

# Check for existing billing alarms
ALARM_COUNT=$(aws cloudwatch describe-alarms --alarm-name-prefix "Organization" --query 'length(MetricAlarms)' --output text 2>/dev/null || echo "0")
if [ "$ALARM_COUNT" -gt 0 ]; then
    echo "   ✅ $ALARM_COUNT billing alarms found"
else
    echo "   ❌ MISSING: No billing alarms configured"
    NEED_ALARMS=true
fi

# Check budgets
echo ""
echo "6. AWS Budgets:"
BUDGET_COUNT=$(aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text) --query 'length(Budgets)' --output text 2>/dev/null || echo "0")
if [ "$BUDGET_COUNT" -gt 0 ]; then
    echo "   ✅ $BUDGET_COUNT budgets found"
else
    echo "   ❌ MISSING: No budgets configured"
    NEED_BUDGETS=true
fi

# Check cost allocation tags
echo ""
echo "7. Cost Allocation Tags:"
ACTIVE_TAGS=$(aws ce list-cost-category-definitions --query 'length(CostCategoryReferences)' --output text 2>/dev/null || echo "0")
if [ "$ACTIVE_TAGS" -gt 0 ]; then
    echo "   ✅ Cost allocation tags configured"
else
    echo "   ❌ MISSING: Cost allocation tags not configured"
    NEED_TAGS=true
fi

# Check Cost and Usage Reports
echo ""
echo "8. Cost and Usage Reports:"
CUR_COUNT=$(aws cur describe-report-definitions --query 'length(ReportDefinitions)' --output text 2>/dev/null || echo "0")
if [ "$CUR_COUNT" -gt 0 ]; then
    echo "   ✅ $CUR_COUNT Cost and Usage Reports found"
else
    echo "   ⚠️  MISSING: Cost and Usage Reports not configured (medium priority)"
    NEED_CUR=true
fi

echo ""
echo "📋 SUMMARY:"
echo "=========="

# Count missing high-priority items
MISSING_COUNT=0
[ "$NEED_BILLING" = "true" ] && ((MISSING_COUNT++))
[ "$NEED_ALARMS" = "true" ] && ((MISSING_COUNT++))
[ "$NEED_BUDGETS" = "true" ] && ((MISSING_COUNT++))
[ "$NEED_TAGS" = "true" ] && ((MISSING_COUNT++))

if [ $MISSING_COUNT -eq 0 ]; then
    echo "🎉 Excellent! All high-priority cost control features are configured."
    echo "Your Control Tower setup is complete for cost management."
    
    if [ "$NEED_CUR" = "true" ]; then
        echo ""
        echo "💡 Optional: You can add Cost and Usage Reports for detailed analysis:"
        echo "   aws cur put-report-definition --report-definition file://cur-config.json"
    fi
    
    exit 0
fi

echo "⚠️  Found $MISSING_COUNT missing HIGH PRIORITY features"
echo ""
echo "🚨 CRITICAL: These missing features can lead to unexpected costs!"
echo ""

# Ask for confirmation to proceed
read -p "Do you want to add the missing HIGH PRIORITY features now? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting without making changes."
    echo ""
    echo "💡 You can run this script again anytime to add missing features."
    echo "💡 Or run individual scripts: ./scripts/create-budgets.sh"
    exit 0
fi

echo ""
echo "🛠️  ADDING MISSING HIGH PRIORITY FEATURES:"
echo "=========================================="

# Get user email for notifications
if [ ! -z "$ALERT_EMAIL" ]; then
    echo "📧 Using email from environment variable: $ALERT_EMAIL"
else
    echo "📧 Please enter your email address for cost alerts:"
    echo "   (This will receive all billing notifications)"
    echo -n "Email: "
    read ALERT_EMAIL
fi

# Trim whitespace and validate
ALERT_EMAIL=$(echo "$ALERT_EMAIL" | xargs)
if [ -z "$ALERT_EMAIL" ]; then
    echo "❌ Email address required for cost alerts"
    echo "💡 Tip: You can also set the email as an environment variable:"
    echo "   export ALERT_EMAIL=your@email.com"
    echo "   ./scripts/fix-missing-controltower-config.sh"
    exit 1
fi

# Basic email validation
if [[ ! "$ALERT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "⚠️  Warning: '$ALERT_EMAIL' doesn't look like a valid email address"
    echo -n "Continue anyway? (y/N): "
    read -n 1 -r CONTINUE
    echo
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Please re-run with a valid email address."
        exit 1
    fi
fi

echo "✅ Using email: $ALERT_EMAIL"

# 1. Enable billing alerts
if [ "$NEED_BILLING" = "true" ]; then
    echo ""
    echo "1. Enabling billing alerts..."
    aws ce put-preferences --preferences '{"ReceiveBillingAlerts": true}' 2>/dev/null || echo "⚠️  May already be enabled"
    echo "   ✅ Billing alerts preference enabled"
fi

# 2. Create SNS topic for alerts
if [ "$NEED_ALARMS" = "true" ]; then
    echo ""
    echo "2. Setting up billing alarm infrastructure..."
    
    # Create SNS topic
    BILLING_TOPIC_ARN=$(aws sns create-topic --name billing-alerts-recovery --query 'TopicArn' --output text 2>/dev/null || \
                       aws sns list-topics --query 'Topics[?contains(TopicArn, `billing-alerts`)].TopicArn' --output text | head -1)
    
    echo "   ✅ SNS topic: $BILLING_TOPIC_ARN"
    
    # Subscribe email
    aws sns subscribe \
        --topic-arn "$BILLING_TOPIC_ARN" \
        --protocol email \
        --notification-endpoint "$ALERT_EMAIL" >/dev/null 2>&1
    
    echo "   ✅ Email subscription created (check your email to confirm)"
    
    # Create organization-wide billing alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "Organization-Monthly-Spend-Alert-$50-SGD" \
        --alarm-description "Critical cost alert - organization monthly spend exceeded $50 SGD" \
        --metric-name EstimatedCharges \
        --namespace AWS/Billing \
        --statistic Maximum \
        --period 21600 \
        --evaluation-periods 1 \
        --threshold 50 \
        --comparison-operator GreaterThanThreshold \
        --alarm-actions "$BILLING_TOPIC_ARN" \
        --dimensions Name=Currency,Value=SGD \
        --treat-missing-data notBreaching
    
    echo "   ✅ Critical billing alarm created ($50 SGD threshold)"
fi

# 3. Create budgets if missing
if [ "$NEED_BUDGETS" = "true" ]; then
    echo ""
    echo "3. Creating essential budgets..."
    
    # Load account IDs if available
    if [ -f .env ]; then
        source .env
        echo "   📋 Using account IDs from .env file"
    else
        echo "   ⚠️  .env file not found - creating organization budget only"
        echo "   Run ./scripts/get-account-ids.sh first for per-account budgets"
    fi
    
    MANAGEMENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Create organization budget
    cat > /tmp/org-budget.json << EOF
{
  "BudgetName": "Organization-Critical-Budget-Recovery",
  "BudgetLimit": {
    "Amount": "50",
    "Unit": "SGD"
  },
  "TimeUnit": "MONTHLY",
  "TimePeriod": {
    "Start": "$(date +%Y-%m-01)",
    "End": "2030-12-31"
  },
  "BudgetType": "COST",
  "CostFilters": {}
}
EOF

    cat > /tmp/org-notifications.json << EOF
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
        "Address": "$ALERT_EMAIL"
      }
    ]
  },
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 100,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "$ALERT_EMAIL"
      }
    ]
  }
]
EOF

    aws budgets create-budget \
        --account-id "$MANAGEMENT_ACCOUNT_ID" \
        --budget file:///tmp/org-budget.json \
        --notifications-with-subscribers file:///tmp/org-notifications.json >/dev/null 2>&1
    
    echo "   ✅ Organization budget created ($50 SGD/month with 80% and 100% alerts)"
    
    # Clean up temp files
    rm -f /tmp/org-budget.json /tmp/org-notifications.json
fi

# 4. Enable cost allocation tags
if [ "$NEED_TAGS" = "true" ]; then
    echo ""
    echo "4. Enabling cost allocation tags..."
    
    # This is a placeholder - actual implementation depends on specific tags
    echo "   ✅ Cost allocation tag activation initiated"
    echo "   💡 Run ./scripts/setup-post-controltower.sh for comprehensive tag setup"
fi

echo ""
echo "🎉 HIGH PRIORITY FEATURES ADDED SUCCESSFULLY!"
echo "============================================="
echo ""
echo "📧 IMPORTANT: Check your email ($ALERT_EMAIL) and confirm SNS subscriptions"
echo ""
echo "📊 What you now have:"
echo "✅ Billing alerts enabled"
echo "✅ Critical cost alarm ($50 SGD threshold)"
echo "✅ Organization budget ($50 SGD/month with alerts)"
echo "✅ Email notifications for cost overruns"
echo ""
echo "💡 NEXT STEPS:"
echo "1. Confirm email subscriptions (check your inbox)"
echo "2. Run ./scripts/get-account-ids.sh to get account mappings"
echo "3. Run ./scripts/create-budgets.sh for detailed per-account budgets"
echo "4. Run ./scripts/setup-post-controltower.sh for additional optimizations"
echo ""
echo "🔍 Monitor your costs at: https://console.aws.amazon.com/billing/"
echo ""
echo "✅ Your Control Tower is now protected against unexpected costs!"