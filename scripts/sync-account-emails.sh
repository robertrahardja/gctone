#!/bin/bash

# Script to sync account emails from AWS Organizations to accounts.ts config
# This script fetches the actual emails from your AWS organization and updates the config

echo "Fetching account emails from AWS Organizations..."

# Get account information and format as TypeScript
aws organizations list-accounts --query "Accounts[?Status=='ACTIVE']" --output json | jq -r '
def map_account_name(name):
  if name == "Development" then "dev"
  elif name == "Staging" then "staging" 
  elif name == "Production" then "prod"
  elif name == "Shared Services" then "shared"
  elif name == "Log Archive" then "logarchive"
  elif name == "Audit" then "audit"
  else "management"
  end;

# Extract workload accounts
.[] | select(.Name | test("Development|Staging|Production|Shared Services")) | 
"    " + map_account_name(.Name) + ": \"" + .Email + "\","

,

# Extract core accounts  
.[] | select(.Name | test("Log Archive|Audit") or (.Name | test("testawsrahardja") and (.Name | test("Development|Staging|Production|Shared Services") | not))) |
if .Name == "Log Archive" then "  logarchive: \"" + .Email + "\","
elif .Name == "Audit" then "  audit: \"" + .Email + "\","
else "  management: \"" + .Email + "\","
end
'

echo ""
echo "Current emails in your AWS accounts:"
aws organizations list-accounts --query "Accounts[?Status=='ACTIVE'].[Name,Email]" --output table

echo ""
echo "To update lib/config/accounts.ts, copy the emails from the table above."
echo "Or run this script and manually update the config file with the output."