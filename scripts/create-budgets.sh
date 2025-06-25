#!/bin/bash

# Create AWS Budgets for all accounts
# Run this after workload accounts are created

set -e

echo "💵 Creating AWS Budgets"
echo "======================"

# Load account IDs
if [ ! -f .env ]; then
    echo "❌ .env file not found. Run ./scripts/get-account-ids.sh first"
    exit 1
fi

source .env

# Get current account ID (management account)
MANAGEMENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Function to create budget
create_budget() {
    local budget_name="$1"
    local amount="$2"
    local account_filter="$3"
    local alert_email="$4"
    
    echo "Creating budget: $budget_name ($amount)"
    
    cat > /tmp/budget-${budget_name}.json << EOF
{
  "BudgetName": "${budget_name}",
  "BudgetLimit": {
    "Amount": "${amount}",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "TimePeriod": {
    "Start": "$(date +%Y-%m-01)",
    "End": "2030-12-31"
  },
  "BudgetType": "COST",
  "CostFilters": {
    "LinkedAccount": ["${account_filter}"]
  }
}
EOF

    cat > /tmp/notifications-${budget_name}.json << EOF
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 50,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${alert_email}"
      }
    ]
  },
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
        "Address": "${alert_email}"
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
        "Address": "${alert_email}"
      }
    ]
  }
]
EOF

    # Create the budget
    aws budgets create-budget \
        --account-id $MANAGEMENT_ACCOUNT_ID \
        --budget file:///tmp/budget-${budget_name}.json \
        --notifications-with-subscribers file:///tmp/notifications-${budget_name}.json
        
    # Clean up temp files
    rm -f /tmp/budget-${budget_name}.json /tmp/notifications-${budget_name}.json
    
    echo "✅ Budget created: $budget_name"
}

# Get email for budget alerts
read -p "Enter email address for budget alerts: " BUDGET_EMAIL

if [ -z "$BUDGET_EMAIL" ]; then
    echo "❌ Email address required"
    exit 1
fi

# Create organization-wide budget
echo "Creating Organization-wide budget..."
create_budget "Organization-Monthly-Budget" "40" "$MANAGEMENT_ACCOUNT_ID,$dev_account_id,$staging_account_id,$shared_account_id,$prod_account_id" "$BUDGET_EMAIL"

# Create per-account budgets if account IDs are available
if [ ! -z "$dev_account_id" ]; then
    create_budget "Development-Monthly-Budget" "8" "$dev_account_id" "$BUDGET_EMAIL"
fi

if [ ! -z "$staging_account_id" ]; then
    create_budget "Staging-Monthly-Budget" "8" "$staging_account_id" "$BUDGET_EMAIL"
fi

if [ ! -z "$shared_account_id" ]; then
    create_budget "Shared-Services-Monthly-Budget" "8" "$shared_account_id" "$BUDGET_EMAIL"
fi

if [ ! -z "$prod_account_id" ]; then
    create_budget "Production-Monthly-Budget" "8" "$prod_account_id" "$BUDGET_EMAIL"
fi

echo ""
echo "🎉 All budgets created successfully!"
echo ""
echo "📧 Budget alerts will be sent to: $BUDGET_EMAIL"
echo "📊 You can view budgets in the AWS Budgets console"
echo ""
echo "💡 Budget thresholds:"
echo "  - 50%: Early warning"
echo "  - 80%: Action required"
echo "  - 100%: Budget exceeded"