# Simple AWS Control Tower + CDK v2 Guide (Universal Template)

A streamlined AWS Control Tower setup with Hello World applications using **CDK v2.201.0+** with **dev/staging/prod** environments. Cost-optimized and simplified for greenfield projects.

> **🇸🇬 Singapore Region Notes**: This guide works universally but includes specific comments for Singapore deployment. Look for 🇸🇬 markers throughout the guide.

---

## Phase 1: Prerequisites and Environment Setup

### 1.1 Verify System Requirements

```bash
# Check Node.js (Need 20+ minimum, 22+ recommended)
node --version
# Expected: v22.x.x (recommended) or v20.x.x (minimum)

# Check npm
npm --version
# Expected: 10.x.x or higher

# Check AWS CLI (need v2.15+)
aws --version
# Expected: aws-cli/2.15.x or higher

# Check Git
git --version
# Expected: git version 2.40.x or higher
```

### 1.2 Install Latest Tools

```bash
# Install Node.js 22 (recommended)
# macOS with Homebrew
brew install node@22
brew link node@22

# Use nvm to install Node 22
nvm install 22
nvm use 22
nvm alias default 22  # Set as default

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install/Update AWS CLI v2
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
```

### 1.3 Configure AWS CLI

**⚠️ IMPORTANT**: Do not use root account credentials for CLI access. Follow security best practices:

#### Option A: Create IAM User (Recommended)

```bash
# 1. Log into AWS Console with root account
# 2. Go to IAM → Users → Create User

# User Creation Form:
# User name: control-tower-admin (or ct-admin, admin-user, etc.)
# Valid characters: A-Z, a-z, 0-9, and + = , . @ _ - (hyphen)
# Up to 64 characters allowed

# Console Access Question:
# "Are you providing console access to a person?"
# Choose: "I want to create an IAM user"
#
# AWS will show a recommendation for Identity Center, but for Control Tower
# setup, we need programmatic access (CLI), so select "I want to create an IAM user"
# This is correct for CDK operations and automation scripts

# 3. Set permissions on next page:
#    Choose: "Attach policies directly"
#    Search and select: "AdministratorAccess"
#    ✅ Check the box next to AdministratorAccess policy

# 4. Review and create user
#    Tags (optional): Add Key="Purpose", Value="ControlTower"
#    Click "Create user"

# 5. After user creation, create access keys:
#    Click on the newly created user → Security credentials tab
#    Scroll to "Access keys" section → "Create access key"
#
#    AWS will show "Access key best practices & alternatives" page:
#
#    Use case selection:
#    ✅ Select: "Command Line Interface (CLI)"
#    Description: "You plan to use this access key to enable the AWS CLI to access your AWS account"
#
#    AWS Alternatives Recommended:
#    - Use AWS CloudShell (browser-based CLI)
#    - Use AWS CLI V2 with IAM Identity Center authentication
#
#    For Control Tower setup, we need persistent CLI access for CDK operations,
#    so access keys are the appropriate choice here.
#
#    Confirmation:
#    ✅ Check: "I understand the above recommendation and want to proceed to create an access key"
#    Click "Next"
#
#    Description (optional): "Control Tower CDK Operations"
#    Click "Create access key"
#
#    ⚠️ CRITICAL: Download .csv file or copy both keys immediately
#    - Access Key ID: Will be visible later
#    - Secret Access Key: This is your ONLY chance to see it!
#
#    Store these securely (password manager, encrypted file, etc.)
#    Never commit these to git or share them

# 6. Enable MFA on IAM user:
#    Security credentials tab → Multi-factor authentication (MFA)
#    "Assign MFA device" → Choose authenticator app
#    Follow setup instructions

# Configure AWS CLI with IAM user credentials
aws configure
# AWS Access Key ID: [IAM user access key from step 5]
# AWS Secret Access Key: [IAM user secret key from step 5]
# Default region name: us-east-1  # or your preferred region
# 🇸🇬 For Singapore: use ap-southeast-1
# Default output format: json

# Verify configuration with IAM user
aws sts get-caller-identity
# use --profile
aws sts get-caller-identity --profile profile-name

# should show: "arn:aws:iam::account:user/control-tower-admin"
# not: "arn:aws:iam::account:root"

# 🇸🇬 singapore-specific: verify singapore region access
# aws sts get-caller-identity --region ap-southeast-1
```

#### option b: using aws profiles (advanced)

```bash
# create named profile for better organization
aws configure --profile control-tower-admin
# use iam user credentials (not root)

# set default profile
export aws_profile=control-tower-admin

# or use profile with each command
aws --profile control-tower-admin sts get-caller-identity
```

#### security best practices

```bash
# ✅ do:
# - create iam user with administratoraccess policy
# - choose "i want to create an iam user" (not identity center for this use case)
# - select "command line interface (cli)" as access key use case
# - acknowledge aws recommendations and proceed with access key creation
# - enable mfa on root account and iam user
# - use iam user credentials for cli operations
# - download/save access keys immediately (you can't see secret key again)
# - store access keys securely (password manager, encrypted storage)
# - delete root access keys after iam user setup
# - rotate access keys regularly (every 90 days)

# ❌ don't:
# - use root account access keys for cli operations
# - share credentials or commit them to version control
# - skip mfa setup on either account
# - use identity center for programmatic/cdk access (use iam user instead)
# - use cloudshell for long-running cdk operations (session timeouts)
# - lose your access keys (you'll need to create new ones)
# - ignore aws security recommendations (but understand when they don't apply)

# 💡 why iam user instead of identity center for this guide?
# - control tower and cdk need programmatic access (access keys)
# - identity center is great for human console access
# - iam users are recommended for automation and cli operations
# - this setup gives you the access needed for control tower deployment
#
# 💡 why access keys instead of aws alternatives?
# - cloudshell: limited session time, not suitable for long cdk deployments
# - identity center cli: adds complexity for single-account control tower setup
# - access keys: provide persistent access needed for control tower automation
# - this is a legitimate use case for access keys (cli automation)
#
# 🔐 access key security:
# - store in secure location (password manager, encrypted file)
# - never commit to version control
# - rotate regularly (every 90 days recommended)
# - delete if compromised
# - monitor usage in cloudtrail
```

### 1.4 install latest cdk v2

```bash
# install cdk v2 globally
npm install -g aws-cdk@latest

# verify installation (should be 2.201.0+)
cdk --version
# expected: 2.201.x or higher
```

---

## phase 2: email accounts setup

### 2.1 prepare email accounts

you'll need 7 email addresses for the accounts. you can use gmail aliases:

- **management account (root)**: `your-email@gmail.com`
- **audit account**: `your-email+audit@gmail.com`
- **log archive account**: `your-email+logs@gmail.com`
- **production workload**: `your-email+prod@gmail.com`
- **staging workload**: `your-email+staging@gmail.com`
- **development workload**: `your-email+dev@gmail.com`
- **shared services**: `your-email+shared@gmail.com`

> **🇸🇬 singapore note**: same email structure works for singapore - the region doesn't affect email requirements.

### 2.2 initial security setup

before proceeding with control tower, secure your root account:

```bash
# ⚠️ critical security steps (do these first!)

# 1. enable mfa on root account
# go to: aws console → account menu (top right) → security credentials
# multi-factor authentication (mfa) → assign mfa device
# use authenticator app (google authenticator, authy, etc.)

# 2. create iam user for daily operations
# go to: iam → users → create user
# user name: control-tower-admin
# permissions: attach administratoraccess policy directly
# create access keys for cli access

# 3. enable mfa on iam user
# iam → users → control-tower-admin → security credentials
# assign mfa device

# 4. test iam user access
aws sts get-caller-identity
# should show iam user arn, not root

# 5. delete root access keys (if any exist)
# aws console → account menu → security credentials
# delete any existing access keys

echo "✅ security setup complete - ready for control tower"
```

---

## phase 3: cdk project structure

### 3.1 initialize project

```bash
# create project directory
mkdir simple-control-tower-cdk
cd simple-control-tower-cdk

# initialize typescript cdk project
cdk init app --language typescript
```

### 3.2 install dependencies

```bash
# install core cdk v2 dependencies
npm install aws-cdk-lib@latest constructs@latest

# install development dependencies
npm install --save-dev @types/node@latest

# verify versions
npm list aws-cdk-lib
```

### 3.3 create directory structure

```bash
# create directory structure
mkdir -p lib/{stacks,constructs,config}
mkdir -p scripts

# create required files
touch lib/config/accounts.ts
touch lib/constructs/hello-world-app.ts
touch lib/stacks/application-stack.ts
touch scripts/deploy.sh
touch scripts/validate.sh
```

---

## phase 4: configuration files

### 4.1 account configuration

create `lib/config/accounts.ts`:

```typescript
export interface accountconfig {
  name: string;
  email: string;
  environment: "prod" | "staging" | "dev" | "shared";
  helloworldmessage: string;
  memorysize: number;
  timeout: number;
}

export const accounts: Record<string, accountconfig> = {
  dev: {
    name: "development",
    email: "your-email+dev@gmail.com", // replace with your email
    environment: "dev",
    helloworldmessage: "hello from development! 💻",
    // 🇸🇬 singapore version: "hello from singapore development! 🇸🇬💻",
    memorysize: 128, // minimal for cost optimization
    timeout: 10,
  },
  staging: {
    name: "staging",
    email: "your-email+staging@gmail.com", // replace with your email
    environment: "staging",
    helloworldmessage: "hello from staging! 🧪",
    // 🇸🇬 singapore version: "hello from singapore staging! 🇸🇬🧪",
    memorysize: 256,
    timeout: 15,
  },
  shared: {
    name: "shared-services",
    email: "your-email+shared@gmail.com", // replace with your email
    environment: "shared",
    helloworldmessage: "hello from shared services! 🔧",
    // 🇸🇬 singapore version: "hello from singapore shared services! 🇸🇬🔧",
    memorysize: 256,
    timeout: 15,
  },
  prod: {
    name: "production",
    email: "your-email+prod@gmail.com", // replace with your email
    environment: "prod",
    helloworldmessage: "hello from production! 🚀",
    // 🇸🇬 singapore version: "hello from singapore production! 🇸🇬🚀",
    memorysize: 512,
    timeout: 30,
  },
};

export const core_accounts = {
  management: "your-email@gmail.com", // replace with your email
  audit: "your-email+audit@gmail.com", // replace with your email
  logarchive: "your-email+logs@gmail.com", // replace with your email
};
```

---

## phase 5: hello world application

### 5.1 create hello world construct

create `lib/constructs/hello-world-app.ts`:

```typescript
import { Construct } from "constructs";
import {
  aws_lambda as lambda,
  aws_apigatewayv2 as apigatewayv2,
  aws_apigatewayv2_integrations as integrations,
  aws_logs as logs,
  CfnOutput,
  Duration,
  RemovalPolicy,
} from "aws-cdk-lib";
import { accountconfig } from "../config/accounts";

export interface helloworldappprops {
  accountconfig: accountconfig;
}

export class helloworldapp extends Construct {
  public readonly api: apigatewayv2.HttpApi;
  public readonly lambda: lambda.Function;

  constructor(scope: Construct, id: string, props: helloworldappprops) {
    super(scope, id);

    const { accountconfig } = props;

    // create log group with cost-optimized retention
    const loggroup = new logs.LogGroup(this, "helloworldloggroup", {
      logGroupName: `/aws/lambda/hello-world-${accountconfig.environment}`,
      retention:
        accountconfig.environment === "prod"
          ? logs.RetentionDays.ONE_MONTH
          : logs.RetentionDays.ONE_WEEK,
      removalPolicy: RemovalPolicy.DESTROY, // cost optimization
    });

    // create lambda function with node.js 22
    this.lambda = new lambda.Function(this, "helloworldfunction", {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: "index.handler",
      code: lambda.Code.fromInline(`
exports.handler = async (event, context) => {
console.log('event received:', json.stringify(event, null, 2));

const response = {
statuscode: 200,
headers: {
'content-type': 'application/json',
'access-control-allow-origin': '*',
'access-control-allow-methods': 'get, post, options',
'access-control-allow-headers': 'content-type, authorization',
},
body: json.stringify({
message: '${accountconfig.helloworldmessage}',
environment: '${accountconfig.environment}',
account: '${accountconfig.name}',
timestamp: new date().toisostring(),
requestid: context.awsrequestid,
region: process.env.aws_region,
version: '1.0.0',
runtime: 'nodejs22.x',
// 🇸🇬 singapore addition: add location metadata
// location: {
//   country: 'singapore',
//   region: 'ap-southeast-1', 
//   timezone: 'asia/singapore',
//   localtime: new date().tolocalestring('en-sg', {
//     timezone: 'asia/singapore'
//   })
// },
metadata: {
remainingtime: context.getremainingtimeinmillis(),
memorylimit: context.memorylimitinmb,
architecture: process.arch,
nodeversion: process.version
}
}, null, 2)
};

return response;
};
`),
      environment: {
        environment: accountconfig.environment,
        account_name: accountconfig.name,
      },
      description: `hello world lambda for ${accountconfig.name} environment`,
      timeout: Duration.seconds(accountconfig.timeout),
      memorySize: accountconfig.memorysize,
      logGroup: loggroup,
      architecture: lambda.Architecture.ARM_64, // cost optimization with graviton
    });

    // create http api (cost-optimized vs rest api)
    this.api = new apigatewayv2.HttpApi(this, "helloworldapi", {
      apiName: `hello world api - ${accountconfig.environment}`,
      description: `hello world http api for ${accountconfig.name} environment`,
      corsPreflight: {
        allowOrigins: ["*"],
        allowMethods: [
          apigatewayv2.CorsHttpMethod.GET,
          apigatewayv2.CorsHttpMethod.POST,
        ],
        allowHeaders: ["content-type", "authorization"],
        maxAge: Duration.days(1),
      },
    });

    // add main route
    this.api.addRoutes({
      path: "/",
      methods: [apigatewayv2.HttpMethod.GET],
      integration: new integrations.HttpLambdaIntegration(
        "rootintegration",
        this.lambda,
      ),
    });

    // simple health check endpoint
    const healthlambda = new lambda.Function(this, "healthfunction", {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: "index.handler",
      code: lambda.Code.fromInline(`
exports.handler = async (event, context) => {
return {
statuscode: 200,
headers: { 'content-type': 'application/json' },
body: json.stringify({
status: 'healthy',
environment: '${accountconfig.environment}',
timestamp: new date().toisostring(),
uptime: process.uptime()
})
};
};
`),
      timeout: Duration.seconds(10),
      memorySize: 128, // minimal for health check
      architecture: lambda.Architecture.ARM_64,
    });

    this.api.addRoutes({
      path: "/health",
      methods: [apigatewayv2.HttpMethod.GET],
      integration: new integrations.HttpLambdaIntegration(
        "healthintegration",
        healthlambda,
      ),
    });

    // outputs
    new CfnOutput(this, "apiurl", {
      value: this.api.apiEndpoint,
      description: `hello world api url for ${accountconfig.environment}`,
      exportName: `helloworldapiurl-${accountconfig.environment}`,
    });

    new CfnOutput(this, "healthcheckurl", {
      value: `${this.api.apiEndpoint}/health`,
      description: `health check url for ${accountconfig.environment}`,
    });
  }
}
```

### 5.2 create application stack

create `lib/stacks/application-stack.ts`:

```typescript
import { Stack, StackProps, Tags } from "aws-cdk-lib";
import { Construct } from "constructs";
import { helloworldapp } from "../constructs/hello-world-app";
import { accountconfig } from "../config/accounts";

export interface applicationstackprops extends StackProps {
  accountconfig: accountconfig;
}

export class applicationstack extends Stack {
  constructor(scope: Construct, id: string, props: applicationstackprops) {
    super(scope, id, props);

    const { accountconfig } = props;

    // create hello world application
    new helloworldapp(this, "helloworldapp", {
      accountconfig,
    });

    // add tags
    Tags.of(this).add("environment", accountconfig.environment);
    Tags.of(this).add("managedby", "cdk");
    Tags.of(this).add("project", "simplecontroltower");
  }
}
```

---

## phase 6: cdk app entry point

### 6.1 update main cdk app

update `bin/simple-control-tower-cdk.ts`:

```typescript
#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { applicationstack } from "../lib/stacks/application-stack";
import { accounts } from "../lib/config/accounts";

const app = new cdk.App();

// deploy application stacks for each environment
Object.entries(accounts).forEach(([key, accountconfig]) => {
  new applicationstack(app, `helloworld-${key}`, {
    accountconfig: accountconfig,
    env: {
      account:
        process.env[`${key.toUpperCase()}_ACCOUNT_ID`] ||
        process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || "us-east-1",
      // 🇸🇬 singapore: change to "ap-southeast-1"
    },
    description: `hello world application for ${accountconfig.name} environment`,
    // 🇸🇬 singapore: add "(singapore)" to description
    stackName: `helloworld-${key}`,
  });
});

// global tags
cdk.Tags.of(app).add("managedby", "cdk");
cdk.Tags.of(app).add("project", "simplecontroltower");
// 🇸🇬 singapore additions:
// cdk.tags.of(app).add("region", "ap-southeast-1");
// cdk.tags.of(app).add("country", "singapore");
// cdk.tags.of(app).add("currency", "sgd");
```

---

## phase 7: deployment scripts

### 7.1 get account ids script

create `scripts/get-account-ids.sh`:

```bash
#!/bin/bash

# Script Purpose: Retrieve AWS account IDs from Control Tower deployment
# This script queries AWS Organizations to get the numeric account IDs for all
# workload accounts created by Control Tower, then stores them in a .env file
# for use by other deployment scripts (bootstrap, deploy, etc.)

echo "🔍 getting account ids from control tower deployment..."
# 🇸🇬 singapore: this script works the same regardless of region

# Function to query AWS Organizations and get account ID by account name
# Takes account name as parameter and returns the numeric account ID
get_account_id() {
local account_name="$1"
# Query AWS Organizations API to list all accounts in the organization
# Filter by account name and return only the account ID
aws organizations list-accounts \
--query "accounts[?name=='$account_name'].id" \
--output text 2>/dev/null
}

# Query each workload account created by Control Tower
# These names must match exactly what was used during Control Tower account creation
prod_account=$(get_account_id "production")
staging_account=$(get_account_id "staging")
dev_account=$(get_account_id "development")
shared_account=$(get_account_id "shared-services")

# Create .env file with all account IDs for use by other scripts
# This file will be sourced by bootstrap-accounts.sh and deploy-applications.sh
cat > .env << eof
# account ids (generated $(date))
# These variables are used by CDK deployment scripts to target specific accounts
prod_account_id=$prod_account
staging_account_id=$staging_account
dev_account_id=$dev_account
shared_account_id=$shared_account

# management account (the account you're currently logged into)
# This is used for cross-account trust relationships during CDK bootstrap
management_account_id=$(aws sts get-caller-identity --query account --output text)

# 🇸🇬 singapore additions:
# aws_region=ap-southeast-1
# aws_default_region=ap-southeast-1
# country=singapore
# timezone=asia/singapore
# currency=sgd
eof

# Display summary of found account IDs for verification
echo "📋 account ids found:"
echo "├── management: $(aws sts get-caller-identity --query account --output text)"
echo "├── production: $prod_account"
echo "├── staging: $staging_account"
echo "├── development: $dev_account"
echo "└── shared services: $shared_account"

echo "💾 account ids saved to .env file"
```

### 7.2 bootstrap accounts script

create `scripts/bootstrap-accounts.sh`:

```bash
#!/bin/bash

# load environment variables
source .env

echo "🔧 cdk bootstrap process"
echo "========================"
# 🇸🇬 singapore: update title to "cdk bootstrap process (singapore)"

# function to bootstrap account
bootstrap_account() {
local account_id="$1"
local account_name="$2"

echo "🚀 bootstrapping $account_name ($account_id)..."
# 🇸🇬 singapore: add "in singapore" to the message

cdk bootstrap aws://$account_id/$aws_default_region \
--qualifier "cdk2024" \
--toolkit-stack-name "cdktoolkit" \
--cloudformation-execution-policies "arn:aws:iam::aws:policy/administratoraccess" \
--trust-accounts $management_account_id
# 🇸🇬 singapore additions:
# --tags region=ap-southeast-1 \
# --tags country=singapore

if [ $? -eq 0 ]; then
echo "✅ $account_name bootstrapped successfully"
# 🇸🇬 singapore: add "in singapore" to success message
else
echo "❌ failed to bootstrap $account_name"
return 1
fi
}

# bootstrap all accounts
bootstrap_account $dev_account "development"
bootstrap_account $staging_account "staging"
bootstrap_account $shared_account "shared services"
bootstrap_account $prod_account "production"

echo "✅ all accounts bootstrapped successfully!"
```

### 7.3 deploy applications script

create `scripts/deploy-applications.sh`:

```bash
#!/bin/bash

# load environment variables
source .env

echo "🚀 deploying hello world applications"
echo "===================================="
# 🇸🇬 singapore: update title to include "(singapore)"

# function to deploy to specific account
deploy_to_account() {
local env_name="$1"
local account_id="$2"
local stack_name="helloworld-$env_name"

echo "📦 deploying $stack_name to account $account_id..."
# 🇸🇬 singapore: add "in singapore" to deployment message

cdk deploy $stack_name \
--context accountid=$account_id \
--require-approval never \
--outputs-file "outputs-$env_name.json"

if [ $? -eq 0 ]; then
echo "✅ $stack_name deployed successfully"

# extract and test api url
api_url=$(cat "outputs-$env_name.json" | jq -r ".[\"$stack_name\"].apiurl" 2>/dev/null)
if [ "$api_url" != "null" ] && [ ! -z "$api_url" ]; then
echo "🌐 api url: $api_url"

# test the endpoint
echo "🧪 testing endpoint..."
response=$(curl -s "$api_url" 2>/dev/null)
if echo "$response" | grep -q "hello"; then
echo "✅ endpoint test successful"
else
echo "⚠️  endpoint test failed"
fi
fi
else
echo "❌ failed to deploy $stack_name"
return 1
fi
echo ""
}

# deploy to each environment (dev -> staging -> shared -> prod)
deploy_to_account "dev" $dev_account
deploy_to_account "staging" $staging_account
deploy_to_account "shared" $shared_account
deploy_to_account "prod" $prod_account

echo "🎉 all applications deployed successfully!"
echo ""
echo "🔗 access your applications:"
for env in dev staging shared prod; do
if [ -f "outputs-$env.json" ]; then
url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
echo "├── $env: $url"
fi
done
```

### 7.4 validation script

create `scripts/validate-deployment.sh`:

```bash
#!/bin/bash

echo "🔍 comprehensive deployment validation"
echo "======================================"
# 🇸🇬 singapore: add "(singapore)" to title

# load environment variables
source .env 2>/dev/null || echo "⚠️  .env file not found"

# check cdk version
cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
echo "✅ cdk version: $cdk_version"
else
echo "❌ cdk version: $cdk_version (expected cdk v2)"
fi

# check node.js version
node_version=$(node --version 2>/dev/null)
if echo "$node_version" | grep -qe "v(20|22)\."; then
echo "✅ node.js version: $node_version"
else
echo "⚠️  node.js version: $node_version (recommended: v20+ or v22+)"
fi

# test applications
environments=("dev" "staging" "shared" "prod")

for env in "${environments[@]}"; do
echo ""
echo "🧪 testing $env environment..."

# get api url
api_url=""
if [ -f "outputs-$env.json" ]; then
api_url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
fi

if [ ! -z "$api_url" ] && [ "$api_url" != "null" ]; then
echo "🌐 api url: $api_url"

# test main endpoint
response=$(curl -s --max-time 10 "$api_url" 2>/dev/null)
if echo "$response" | grep -q "hello"; then
echo "✅ main endpoint working"

# extract environment from response
env_from_response=$(echo "$response" | jq -r '.environment' 2>/dev/null)
if [ "$env_from_response" = "$env" ]; then
echo "✅ environment validation passed"
else
echo "⚠️  environment mismatch: expected $env, got $env_from_response"
fi
else
echo "❌ main endpoint test failed"
fi

# test health endpoint
health_url="${api_url%/}/health"
health_response=$(curl -s --max-time 10 "$health_url" 2>/dev/null)
if echo "$health_response" | grep -q "healthy"; then
echo "✅ health endpoint working"
else
echo "⚠️  health endpoint test failed"
fi
else
echo "❌ stack not found or not deployed: helloworld-$env"
fi
done

echo ""
echo "📊 validation summary"
echo "===================="
echo "✅ validation completed at $(date)"
echo ""
echo "🚀 next steps:"
echo "1. access your hello world applications using the urls above"
echo "2. monitor costs in aws cost explorer"
echo "3. set up ci/cd pipeline: dev → staging → prod"
echo "4. add your custom applications to each environment"
```

---

## phase 8: complete setup script

### 8.1 master setup script

create `scripts/complete-setup.sh`:

```bash
#!/bin/bash

set -e

echo "🚀 complete simple control tower + cdk v2 setup"
echo "==============================================="
# 🇸🇬 singapore: update title to include "(singapore edition)"

# step 1: prerequisites
echo "📋 step 1: checking prerequisites..."
# 🇸🇬 singapore: add region verification step here

node_version=$(node --version)
if echo "$node_version" | grep -qe "v(20|22)\."; then
echo "✅ node.js version: $node_version"
else
echo "❌ node.js version $node_version not supported. need v20+ or v22+"
exit 1
fi

cdk_version=$(cdk --version 2>/dev/null)
if echo "$cdk_version" | grep -q "2\."; then
echo "✅ cdk version: $cdk_version"
else
echo "❌ cdk version $cdk_version not supported. need cdk v2"
exit 1
fi

# step 2: build project
echo "📋 step 2: building project..."
npm run build

if [ $? -eq 0 ]; then
echo "✅ project built successfully"
else
echo "❌ project build failed"
exit 1
fi

# step 3: synthesize cdk
echo "📋 step 3: synthesizing cdk..."
cdk synth

if [ $? -eq 0 ]; then
echo "✅ cdk synthesis completed"
else
echo "❌ cdk synthesis failed"
exit 1
fi

# step 4: check control tower
echo "📋 step 4: checking control tower status..."

# note: this requires control tower to be manually set up first
echo "⚠️  manual setup required:"
echo "1. go to aws control tower console"
# 🇸🇬 singapore: add specific url
# echo "1. go to: https://ap-southeast-1.console.aws.amazon.com/controltower/"
echo "2. click 'set up landing zone'"
# 🇸🇬 singapore: add region selection step
# echo "3. select home region: asia pacific (singapore) ap-southeast-1"
# echo "4. optional: add sydney (ap-southeast-2) for disaster recovery"
echo "3. configure with your email addresses from accounts.ts"
echo "4. wait for setup to complete (30-45 minutes)"
echo "5. re-run this script after control tower is ready"

# check if control tower is available
aws controltower list-landing-zones 2>/dev/null >/dev/null
if [ $? -eq 0 ]; then
echo "✅ control tower cli access confirmed"
else
echo "⚠️  control tower not available yet"
echo "continue with manual setup and run the remaining steps manually"
fi

# step 5: get account ids
echo "📋 step 5: getting account ids..."
./scripts/get-account-ids.sh

# step 6: bootstrap accounts
echo "📋 step 6: bootstrapping accounts..."
./scripts/bootstrap-accounts.sh

# step 7: deploy applications
echo "📋 step 7: deploying applications..."
./scripts/deploy-applications.sh

# step 8: validate
echo "📋 step 8: validating deployment..."
./scripts/validate-deployment.sh

echo ""
echo "🎉 simple control tower + cdk v2 setup complete!"
echo ""
echo "📊 what was deployed:"
echo "├── 💻 development: cost-optimized, minimal resources"
echo "├── 🧪 staging: pre-production testing"
echo "├── 🔧 shared services: shared resources"
echo "└── 🚀 production: full resources"
echo ""
echo "🔗 your hello world applications:"
for env in dev staging shared prod; do
if [ -f "outputs-$env.json" ]; then
url=$(cat "outputs-$env.json" | jq -r ".\"helloworld-$env\".apiurl" 2>/dev/null)
echo "├── $env: $url"
fi
done
```

---

## phase 9: package.json scripts

### 9.1 update package.json

update `package.json` to include deployment scripts:

```json
{
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "test": "jest",
    "cdk": "cdk",
    "synth": "cdk synth",
    "deploy": "cdk deploy",
    "destroy": "cdk destroy",
    "diff": "cdk diff",
    "validate": "npm run build && npm run test && cdk synth",
    "bootstrap": "cdk bootstrap",
    "deploy:dev": "cdk deploy helloworld-dev --require-approval never",
    "deploy:staging": "cdk deploy helloworld-staging --require-approval never",
    "deploy:prod": "cdk deploy helloworld-prod --require-approval never",
    "deploy:shared": "cdk deploy helloworld-shared --require-approval never",
    "deploy:all": "npm run deploy:dev && npm run deploy:staging && npm run deploy:shared && npm run deploy:prod",
    "test:endpoints": "./scripts/validate-deployment.sh",
    "setup:complete": "./scripts/complete-setup.sh"
  }
}
```

---

## quick start commands

### complete setup (after control tower manual setup)

````bash
# 🔐 security setup first (one-time setup)
# 1. enable mfa on root account in aws console
# 2. create iam user 'control-tower-admin' with administratoraccess
# 3. enable mfa on iam user
# 4. create access keys for iam user
# 5. delete any root account access keys

# 1. prerequisites check
node --version  # should be v20+ or v22+
aws --version   # should be v2.15+
cdk --version   # should be v2.201+

# 🇸🇬 singapore: set region before starting
# aws configure set region ap-southeast-1

# configure cli with iam user credentials (not root)
aws configure
# use your iam user access keys here

# 2. project setup
mkdir simple-control-tower-cdk
cd simple-control-tower-cdk
cdk init app --language typescript

# 3. install dependencies
npm install aws-cdk-lib@latest constructs@latest

# 4. update email addresses in lib/config/accounts.ts
# replace "your-email" with your actual email address
# 🇸🇬 singapore: also update hello world messages with singapore flags

# 5. Manual Control Tower Setup (Required First!)

## ⚠️ Prerequisites
- **Use ROOT account credentials** to log into AWS Console for this step
- Ensure you have access to the email addresses configured in `accounts.ts`
- Have your credit card ready for account verification (if required)
- Budget 30-45 minutes for the complete setup process

## 🇸🇬 Singapore Region Setup

### Step 1: Access Control Tower Console

1. Log into AWS Console with **ROOT account credentials**
2. Navigate to: <https://ap-southeast-1.console.aws.amazon.com/controltower/>
3. **Verify you are in Singapore** `ap-southeast-1` **region** in the top-right corner

### Step 2: Landing Zone Configuration

1. Click **"Set up landing zone"** button
2. **Home Region Selection:**
- Select **"Asia Pacific (Singapore) ap-southeast-1"** as home region
- This cannot be changed later, so double-check!

### Step 3: Organizational Unit (OU) Configuration

1. **Foundation OU Names:**
- Security OU: `Security` (recommended default)
- Sandbox OU: `Sandbox` (recommended default)
2. **Additional OUs (Optional):**
- You can create custom OUs later for workload accounts
- For this project, default OUs are sufficient

### Step 4: Account Configuration

Configure the three core accounts using emails from your `accounts.ts`:

#### Management Account (Already Your Current Account)

- **Email:** `testawsrahardja@gmail.com` (your root account email)
- **Purpose:** Control Tower management and billing consolidation

#### Audit Account

- **Email:** `testawsrahardjaaudit@gmail.com`
- **Account Name:** `Audit Account`
- **Purpose:** Security monitoring and compliance
- **OU Placement:** Security OU

#### Log Archive Account

- **Email:** `testawsrahardjalogs@gmail.com`
- **Account Name:** `Log Archive Account`
- **Purpose:** Centralized logging and CloudTrail storage
- **OU Placement:** Security OU

### Step 5: Compliance and Governance Configuration

1. **Guardrails Selection:**

- **Preventive Guardrails:** Enable all recommended (default)
- **Detective Guardrails:** Enable all recommended (default)
- These provide security and compliance baselines

2. **CloudTrail Configuration:**

- **Organization CloudTrail:** Enable (recommended)
- **Log retention:** 90 days (default)
- **S3 bucket:** Auto-created in Log Archive account

3. **AWS Config Configuration:**
- **Enable AWS Config:** Yes (required for guardrails)
- **Config rules:** Auto-configured for compliance

### Step 6: Cost and Billing Setup

Configure financial monitoring and cost controls for your AWS organization:

#### 1. **Cost Reporting** (Recommended)
- **What it does:** Enables AWS Cost and Usage Reports (CUR) for the entire organization
- **Benefits:**
- Track costs per account, service, and resource
- Generate detailed financial reports with hourly/daily usage data
- Enable third-party cost management tools
- **Action:** Check "Enable Cost and Usage Reports" during setup
- **Result:** Control Tower automatically creates CUR reports stored in management account S3

#### 2. **Billing Alerts** (Optional but Recommended)
- **What it does:** Creates CloudWatch alarms for spending thresholds
- **Configuration:**
- Set monthly spending thresholds (e.g., $50, $100, $500)
- Choose notification email addresses
- Define alert frequency (daily, weekly, monthly)
- **Examples:**
- "Alert when monthly spend exceeds $100"
- "Daily alert when approaching budget limit"
- "Immediate alert for unusual spending spikes"

#### 3. **Budget Allocation** (Recommended for Production)
- **What it does:** Creates AWS Budgets for proactive cost control
- **Recommended budget structure:**
```
Management Account: $20/month (governance only)
Audit Account: $10/month (monitoring/logging)
Log Archive: $30/month (storage costs)
Dev Account: $50/month (development work)
Staging Account: $100/month (testing)
Prod Account: $500/month (production workload)
```
- **Budget actions:**
- Email notifications at 50%, 80%, 100% of budget
- Optional: Automatically stop resources at budget limit
- Integration with AWS Cost Explorer for analysis

#### 4. **Best Practices**
- **Start conservative:** Set lower budgets initially, adjust based on usage
- **Use consistent tagging:** Implement tagging strategy for cost allocation
- **Monitor regularly:** Review cost reports weekly/monthly
- **Set multiple thresholds:** Configure alerts at 50%, 80%, and 100% of budget

### Step 7: Review and Launch

1. **Review all configurations carefully**
2. **Estimated costs:** Review the cost breakdown
3. **Time estimate:** 20-60 minutes for setup completion
4. Click **"Set up landing zone"**

## 🕐 Setup Progress Monitoring

### Expected Timeline

- **Initial setup:** 5-10 minutes
- **Account creation:** 10-20 minutes per account
- **Guardrails deployment:** 20-40 minutes
- **Total time:** 30-70 minutes

### Progress Tracking

1. **Monitor the setup dashboard** - shows real-time progress
2. **Check email confirmations** for new account creations
3. **Verify account access** as accounts are created

### Common Setup Issues and Solutions

#### Issue: Email Already in Use

- **Solution:** Use Gmail aliases (<email+alias@gmail.com>)
- **Example:** If `test@gmail.com` exists, use `test+audit@gmail.com`

#### Issue: Region Selection Error

- **Solution:** Ensure you are in ap-southeast-1 before starting
- **Note:** This cannot be changed after setup begins

#### Issue: Credit Card Verification Required

- **Solution:** Have a valid credit card ready for account verification
- **Note:** This is normal for new AWS accounts

#### Issue: Setup Timeout or Failure

- **Solution:** Contact AWS Support if setup fails after 2 hours
- **Alternative:** Delete failed setup and restart (if option available)

## 📧 Email Management Strategy

### Gmail Alias Configuration

All accounts use the same base email with aliases:

```

Management: <testawsrahardja@gmail.com>
Audit: <testawsrahardjaaudit@gmail.com>
Log Archive: <testawsrahardjalogs@gmail.com>
Dev: <testawsrahardja+dev@gmail.com>
Staging: <testawsrahardja+staging@gmail.com>
Shared: <testawsrahardja+shared@gmail.com>
Prod: <testawsrahardja+prod@gmail.com>

```

### Email Forwarding Setup

1. **All emails go to your main inbox**
2. **Set up Gmail filters** to organize by account:
- Filter: `to:testawsrahardjaaudit@gmail.com`
- Action: Apply label "AWS-Audit"
3. **Repeat for each account type**

## ✅ Post-Setup Verification

### Step 1: Verify Account Creation

1. Check **AWS Organizations** console
2. Confirm all 3 core accounts are listed
3. Verify account IDs and email addresses

### Step 2: Test Account Access

1. **Switch roles** to Audit and Log Archive accounts
2. Verify **OrganizationAccountAccessRole** works
3. Confirm **read-only access** in Audit account

### Step 3: Verify Guardrails

1. Go to **Control Tower dashboard**
2. Check **guardrails status** - should show "Compliant"
3. Review **non-compliance** items if any

### Step 4: CloudTrail Verification

1. Navigate to **CloudTrail** in Log Archive account
2. Verify **organization trail** is active
3. Check **S3 bucket** for log delivery

## 🚀 Next Steps After Setup

1. **Create workload accounts** (dev, staging, shared, prod)
2. **Configure SSO** (optional but recommended)
3. **Set up billing alerts** and budgets
4. **Deploy CDK bootstrap** to all accounts
5. **Begin application deployment**

## 🔧 Troubleshooting: OU Re-registration Guide

### When You Need This Guide
If you see **"Inheritance drift"** warnings in Control Tower console, some accounts do not match the baseline configuration applied to their OU. This commonly occurs in the **Sandbox OU**.

### ⚠️ Prerequisites and Preparation

#### Before You Start:
1. **Use Management Account credentials** (ROOT or IAM user with Control Tower permissions)
2. **Schedule maintenance window** - Process can take 20-60 minutes
3. **Document current configurations** in affected accounts
4. **Notify users** of potential service disruptions
5. **Backup critical settings** that might be reset

#### What Will Happen:
- All accounts in the OU will be reset to baseline configuration
- Custom IAM policies may be overwritten
- Non-compliant configurations will be removed
- Guardrails will be re-applied consistently

### 🚀 Step-by-Step Re-registration Process

#### Step 1: Access Control Tower Console
1. Log into AWS Console with **Management Account**
2. Navigate to **Control Tower** service
3. Go to **Organization** section in left navigation
4. Select **Organizational units**

#### Step 2: Locate Affected OU
1. Find the OU showing **inheritance drift** (e.g., "Sandbox")
2. Click on the **OU name** to view details
3. Look for **compliance status** indicators
4. Note any **"Inheritance drift"** warnings or red status indicators

#### Step 3: Identify Affected Accounts
1. In OU details, review **"Accounts"** tab
2. Note which accounts show **drift status**
3. Click on individual accounts to see **specific drift details**
4. Document any **critical configurations** that might be lost

#### Step 4: Initiate Re-registration
1. In the OU details page, look for **"Re-register OU"** button
2. Click **"Re-register OU"**
3. **Select baseline version:** Choose "Latest" for most current guardrails
4. **Review baseline configuration** that will be applied
5. **Review affected accounts list**
6. **Acknowledge potential data loss warning**
7. Click **"Re-register organizational unit"**
8. **Confirm the action** in popup dialog

### 📊 Monitoring Re-registration Progress

#### Expected Timeline:
- **Initiation:** 2-5 minutes
- **Per account processing:** 5-15 minutes each
- **Total time:** 20-60 minutes (depends on number of accounts)

#### Progress Indicators:
1. **OU Status:** Changes to "Update in progress"
2. **Account Status:** Individual accounts show "Updating"
3. **Guardrail Status:** Shows "Applying" or "In progress"
4. **Dashboard Notifications:** Real-time updates

### ✅ Post-Re-registration Verification

#### Step 1: Verify OU Compliance
1. Check **OU status** shows "Compliant"
2. Verify **no inheritance drift** warnings
3. Confirm all **guardrails show green status**

#### Step 2: Test Account Access
1. **Switch roles** to accounts in the OU
2. Verify **OrganizationAccountAccessRole** works
3. Test **basic AWS service access**
4. Confirm **logging is functioning**

#### Step 3: Restore Necessary Customizations
1. **Re-apply approved custom configurations**
2. **Restore necessary IAM policies** (following best practices)
3. **Update application configurations** if needed
4. **Test application functionality**

### ⚠️ Troubleshooting Common Issues

#### Issue 1: Re-registration Fails
**Solutions:**
- Check **AWS Service Health** for outages
- Verify **sufficient permissions** in management account
- Try again during **off-peak hours**
- Contact **AWS Support** if problem persists

#### Issue 2: Account Access Lost
**Solutions:**
- Wait for **complete process completion** (up to 60 minutes)
- Verify **OrganizationAccountAccessRole** exists
- Use **root account** of individual accounts if needed

#### Issue 3: Applications Stop Working
**Solutions:**
- Check **IAM role permissions** were reset
- Verify **resource-based policies** are intact
- Restore **necessary custom configurations**
- Review **CloudTrail logs** for permission errors

### 🔄 Prevention of Future Drift

#### Best Practices:
1. **Use Account Factory** for new accounts
2. **Make changes through Control Tower** rather than directly
3. **Use Service Catalog** for approved customizations
4. **Regular compliance monitoring** (weekly/monthly)
5. **Avoid manual IAM changes** in managed accounts

## 🚀 Next Steps After Control Tower Setup

### What to Do Immediately After Manual Control Tower Setup

Once Control Tower setup is complete and any inheritance drift issues are resolved, follow these prioritized steps:

#### Step 1: **Create Workload OUs and Accounts** (Priority 1)

First create the organizational structure, then the workload accounts:

##### **1A. Create Organizational Units (OUs)**

1. **Access Organizations Console:**
- Go to AWS Organizations console → **Organizational units**
- You will see existing OUs: Root, Security, Sandbox

2. **Create Non-Production OU:**
- Click **"Create organizational unit"**
- **Name:** `Non-Production`
- **Description:** `Workload accounts for development, staging, and shared services`
- **Parent:** Root

3. **Create Production OU:**
- Click **"Create organizational unit"**
- **Name:** `Production`
- **Description:** `Production workload accounts with enhanced security`
- **Parent:** Root

**Recommended OU Structure for Small Teams (<10 people):**
```
Root Organization
├── Security OU (Control Tower managed)
├── Sandbox OU (Control Tower managed)
├── Non-Production OU (create new)
└── Production OU (create new)
```

##### **1B. Create Workload Accounts**

Use **Account Factory** in Control Tower console:

1. **Access Account Factory:**
- Go to Control Tower console → **Account Factory**
- Click **"Enroll account"** or **"Create account"**

2. **Create Development Account:**
- **Account email:** `testawsrahardja+dev@gmail.com`
- **Account name:** `Development`
- **OU:** `Non-Production` (select from dropdown)
- **Access configuration (SSO):**
- **IAM Identity Center user email:** `testawsrahardja+dev@gmail.com`
- **IAM Identity Center user name:** `Robert Rahardja` (your full name)

3. **Create Staging Account:**
- **Account email:** `testawsrahardja+staging@gmail.com`
- **Account name:** `Staging`
- **OU:** `Non-Production` (same OU as Development)
- **Access configuration (SSO):**
- **IAM Identity Center user email:** `testawsrahardja+staging@gmail.com`
- **IAM Identity Center user name:** `Robert Rahardja`

4. **Create Shared Services Account:**
- **Account email:** `testawsrahardja+shared@gmail.com`
- **Account name:** `Shared Services`
- **OU:** `Non-Production` (same OU as Development/Staging)
- **Access configuration (SSO):**
- **IAM Identity Center user email:** `testawsrahardja+shared@gmail.com`
- **IAM Identity Center user name:** `Robert Rahardja`

5. **Create Production Account:**
- **Account email:** `testawsrahardja+prod@gmail.com`
- **Account name:** `Production`
- **OU:** `Production` (separate OU for enhanced security)
- **Access configuration (SSO):**
- **IAM Identity Center user email:** `testawsrahardja+prod@gmail.com`
- **IAM Identity Center user name:** `Robert Rahardja`

**Timeline:** 10-15 minutes to create OUs + 15-30 minutes per account creation

##### **Why This OU Structure Works for Small Teams:**

**Benefits:**
- **Simple governance** - Only 2 workload OUs to manage instead of 4
- **Clear separation** - Production isolated for security and compliance
- **Cost effective** - Shared policies across non-production environments
- **Team friendly** - Easy to understand and navigate for <10 person teams
- **Growth ready** - Can easily add more accounts to existing OUs

**Access Patterns:**
- **Non-Production OU:** Daily development work (Dev, Staging, Shared Services)
- **Production OU:** Protected environment with stricter controls
- **Developers:** Primarily work in Non-Production OU accounts
- **DevOps/Leads:** Access to both OUs with appropriate permissions

**Governance:**
- **Non-Production OU:** More permissive guardrails for development/testing
- **Production OU:** Strict security policies and compliance controls

#### Step 1C: **Configure IAM Identity Center (SSO)** (Priority 1)

After creating accounts, configure SSO for secure team access:

##### **1. Access IAM Identity Center Console**
1. **Navigate to Identity Center:**
   - Go to AWS Console → **IAM Identity Center**
   - Or search for "SSO" or "Identity Center"
   - Ensure you are in the **management account**

2. **Verify Identity Center is Enabled:**
   - Should show "Identity Center is enabled in this organization"
   - If not enabled, click **"Enable"** (Control Tower should have done this)

##### **2. Configure Access Portal**
1. **Set up Access Portal:**
   - Go to **Settings** → **Identity Center configuration**
   - **Identity source:** Choose "Identity Center directory" (default)
   - **Access portal URL:** Note the URL (e.g., `https://d-xxxxxxxxxx.awsapps.com/start`)
   - **Session duration:** Set to desired length (default 8 hours)

##### **3. Create Permission Sets**
Create role-based permission sets for different access levels:

1. **Create Developer Permission Set:**
   - Go to **Permission sets** → **Create permission set**
   - **Name:** `DeveloperAccess`
   - **Description:** `Developer access to non-production environments`
   - **Permission policies:**
     - `PowerUserAccess` (recommended for developers)
     - Or create custom policy with specific permissions
   - **Session duration:** 8 hours

2. **Create Admin Permission Set:**
   - **Name:** `AdminAccess`
   - **Description:** `Administrative access to all environments`
   - **Permission policies:** `AdministratorAccess`
   - **Session duration:** 4 hours (shorter for security)

3. **Create ReadOnly Permission Set:**
   - **Name:** `ReadOnlyAccess`
   - **Description:** `Read-only access for monitoring and auditing`
   - **Permission policies:** `ReadOnlyAccess`
   - **Session duration:** 12 hours

##### **4. Assign Users to Accounts**
Assign the SSO users created during account setup to appropriate accounts:

1. **Go to AWS accounts:**
   - Navigate to **AWS accounts** in Identity Center
   - You should see all your workload accounts listed

2. **Assign Users to Non-Production Accounts:**
   - Select **Development account**
   - Click **Assign users or groups**
   - Select your SSO user (`Robert Rahardja`)
   - **Permission set:** `DeveloperAccess` or `AdminAccess`
   - Repeat for **Staging** and **Shared Services** accounts

3. **Assign Users to Production Account:**
   - Select **Production account**
   - Click **Assign users or groups**
   - Select your SSO user
   - **Permission set:** `AdminAccess` (restrict as needed)

##### **5. Add Team Members (When Team Grows)**
To add additional team members:

1. **Create New Users:**
   - Go to **Users** → **Add user**
   - **Username:** `teammate1` (no spaces)
   - **Email:** `teammate1@company.com`
   - **First name:** `Team`
   - **Last name:** `Member`
   - **Display name:** `Team Member`

2. **Assign to Accounts:**
   - Go to **AWS accounts**
   - Select appropriate accounts
   - Assign new user with appropriate permission sets

##### **6. Access Your Accounts via SSO**

1. **Get Your Access Portal URL:**
   - Go to **Settings** → **Identity Center configuration**
   - Copy the **Access portal URL**
   - Bookmark this URL for easy access

2. **Login Process:**
   - Go to your access portal URL
   - **Username:** Your SSO email (e.g., `testawsrahardja+dev@gmail.com`)
   - **Password:** Set during first login
   - **MFA:** Configure when prompted (highly recommended)

3. **Access Accounts:**
   - After login, you will see all assigned accounts
   - Click on account → Select role → **Management console** or **Command line or programmatic access**

##### **7. Command Line Access Setup**
For CLI/CDK operations:

1. **Install AWS CLI v2** (if not already installed)
2. **Configure SSO profile:**
   ```bash
   aws configure sso
   # SSO start URL: [your access portal URL]
   # SSO region: [your region, e.g., ap-southeast-1]
   # Account ID: [select from list]
   # Role name: [select permission set]
   # CLI default client Region: ap-southeast-1
   # CLI default output format: json
   # CLI profile name: dev-sso
   ```

3. **Use SSO profile:**
   ```bash
   # Login to SSO
   aws sso login --profile dev-sso

   # Use the profile
   aws sts get-caller-identity --profile dev-sso

   # Set as default
   export AWS_PROFILE=dev-sso
   ```

##### **SSO Benefits for Small Teams:**
- **Security:** No shared root account access
- **Audit trail:** Clear logging of who did what
- **Scalability:** Easy to add team members
- **Convenience:** Single sign-on across all accounts
- **Compliance:** Meets enterprise security standards

#### Step 2: **Get Account IDs** (Priority 2)
Once all accounts are created:

```bash
# Run the account ID retrieval script
./scripts/get-account-ids.sh
```

**This script will:**
- Query AWS Organizations for all account IDs
- Create `.env` file with account mappings
- Verify account access and permissions

**Expected output:** `.env` file with all account IDs

#### Step 3: **Bootstrap CDK in All Accounts** (Priority 2)
Prepare all accounts for CDK deployments:

```bash
# Load the account IDs and bootstrap all accounts
source .env
./scripts/bootstrap-accounts.sh
```

**This process will:**
- Install CDK toolkit in each workload account
- Set up cross-account trust relationships
- Create necessary S3 buckets and IAM roles
- Prepare accounts for CDK deployments

**Timeline:** 5-10 minutes per account

#### Step 4: **Deploy Hello World Applications** (Priority 3)
Deploy the sample applications to all environments:

```bash
# Deploy applications to all accounts
./scripts/deploy-applications.sh
```

**This will:**
- Deploy Hello World applications to all environments
- Create API Gateway endpoints for each account
- Set up environment-specific configurations
- Generate output files with API URLs

**Timeline:** 10-15 minutes total

#### Step 5: **Validate Deployment** (Priority 3)
Verify everything is working correctly:

```bash
# Validate all deployments
./scripts/validate-deployment.sh
```

**This will:**
- Test all API endpoints
- Verify environment configurations
- Confirm cross-account access
- Check application functionality

#### Step 6: **Set Up Cost Monitoring** (Optional but Recommended)
Configure financial monitoring:

1. **Go to AWS Billing & Cost Management**
2. **Set up billing alerts:**
   - Monthly spend alerts for each account
   - Organization-wide spending alerts
3. **Create budgets:**
   - Per-account budgets based on expected usage
   - Alert thresholds at 50%, 80%, 100%
4. **Enable cost allocation tags:**
   - Environment tags
   - Project tags
   - Owner tags

### Alternative: Complete Automated Setup

If you prefer to run everything at once after Control Tower setup:

```bash
# Complete setup script (after manual Control Tower setup)
npm run setup:complete
```

**This runs all steps automatically:**
1. Prerequisites check
2. Project build and synthesis
3. Account ID retrieval
4. CDK bootstrapping
5. Application deployment
6. Validation testing

### Verification Checklist

After completing all steps, verify:

- [ ] **Control Tower status:** All OUs showing "Compliant"
- [ ] **Account access:** Can switch roles to all workload accounts
- [ ] **Applications deployed:** All environments have working API endpoints
- [ ] **Monitoring setup:** Cost alerts and budgets configured
- [ ] **Documentation:** All account IDs and URLs documented

### Expected Timeline Summary

| Step | Time Required | Prerequisites |
|------|---------------|---------------|
| Create workload accounts | 60-120 minutes | Control Tower setup complete |
| Get account IDs | 2-5 minutes | All accounts created |
| Bootstrap CDK | 20-40 minutes | Account IDs available |
| Deploy applications | 10-15 minutes | CDK bootstrap complete |
| Validate deployment | 5-10 minutes | Applications deployed |
| **Total** | **~2-3 hours** | Control Tower operational |

### Ready for Development

Once these steps are complete, you will have:
- ✅ **Multi-account AWS environment** with proper governance
- ✅ **Working Hello World applications** in all environments
- ✅ **Cost monitoring and alerts** configured
- ✅ **CDK deployment pipeline** ready for your applications
- ✅ **Security baseline** enforced across all accounts

You can now begin developing and deploying your actual applications using the established multi-account structure!

## 📞 Support Resources

- **AWS Control Tower Documentation:** <https://docs.aws.amazon.com/controltower/>
- **AWS Support:** If setup fails or takes >2 hours
- **AWS Forums:** Community support for common issues
- **Cost Calculator:** <https://calculator.aws/> for cost estimation

# 6. bootstrap cdk (use iam user cli credentials)

cdk bootstrap

# 🇸🇬 singapore: cdk bootstrap --region ap-southeast-1

# 7. get account ids and deploy

./scripts/get-account-ids.sh
./scripts/bootstrap-accounts.sh
./scripts/deploy-applications.sh

# 8. validate deployment

./scripts/validate-deployment.sh

# 9. test individual environments

npm run deploy:dev
npm run deploy:staging
npm run deploy:prod
npm run test:endpoints

````

### individual environment commands

```bash
# ⚠️ ensure you're using iam user credentials, not root
aws sts get-caller-identity  # should show iam user arn

# deploy to specific environment
npm run deploy:dev
npm run deploy:staging
npm run deploy:prod
npm run deploy:shared

# deploy all at once
npm run deploy:all

# test all endpoints
npm run test:endpoints

# complete automated setup (after control tower manual setup)
npm run setup:complete
```

### 🔐 security troubleshooting

```bash
# if you get permission errors:

# 1. verify you're using iam user (not root)
aws sts get-caller-identity
# should show: "arn:aws:iam::account:user/control-tower-admin"
# not: "arn:aws:iam::account:root"

# 2. check iam user has administratoraccess
aws iam list-attached-user-policies --user-name control-tower-admin

# 3. for control tower operations, you may need to assume organizationaccountaccessrole
# this is normal for cross-account operations

# 4. if cdk bootstrap fails due to scps, try:
cdk bootstrap --trust-accounts management_account_id --cloudformation-execution-policies arn:aws:iam::aws:policy/administratoraccess
```

---

## cost optimization features

this template includes several cost optimization features:

### 🏗️ **architecture choices**

- **http api** instead of rest api (up to 70% cheaper)
- **arm64 lambda** architecture (up to 20% cheaper)
- **minimal memory allocation** for dev environments

### 📊 **environment-specific sizing**

- **development**: 128mb memory, 10s timeout
- **staging**: 256mb memory, 15s timeout
- **production**: 512mb memory, 30s timeout

### 🗃️ **log retention**

- **development**: 1 week retention
- **staging**: 1 week retention
- **production**: 1 month retention

### 🏷️ **resource management**

- all resources tagged for cost tracking
- removal policy set to destroy for easy cleanup
- no unnecessary persistent resources

### 🇸🇬 **singapore pricing considerations**

- **regional difference**: singapore typically 10-15% higher than us-east-1
- **still optimized**: all cost features work the same in singapore
- **expected costs**: ~$2-20 sgd per environment for minimal usage
- **currency tracking**: add sgd tags for cost management

---

## summary

this simplified template provides:

✅ **modern cdk v2** with aws-cdk-lib  
✅ **node.js 22** lambda runtime  
✅ **cost-optimized** http apis and arm64 architecture  
✅ **multi-environment** structure (dev/staging/prod/shared)  
✅ **simple deployment** scripts  
✅ **universal template** - works in any region  
✅ **greenfield ready** - minimal dependencies

the template removes all singapore-specific compliance features while maintaining the solid multi-account control tower foundation you can build upon anywhere.

### 🇸🇬 quick singapore adaptation

to use this template in singapore, simply:

1. **set region**: `aws configure set region ap-southeast-1`
2. **update cdk app**: change region to `ap-southeast-1` in `bin/simple-control-tower-cdk.ts`
3. **control tower setup**: select singapore as home region in console
4. **optional**: add singapore flags to hello world messages and location metadata

all cost optimizations and architectural benefits remain the same!

### 🔐 security summary

**✅ always use iam user credentials for cli operations**

- root account: only for initial setup and emergencies
- iam user: daily operations, cdk deployments, control tower management
- mfa: enabled on both root and iam user accounts
- access keys: only on iam user, never on root account

this approach provides the same functionality with enterprise-grade security! 🚀
