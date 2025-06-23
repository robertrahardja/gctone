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

echo "🔍 getting account ids from control tower deployment..."
# 🇸🇬 singapore: this script works the same regardless of region

# function to get account id by name
get_account_id() {
    local account_name="$1"
    aws organizations list-accounts \
        --query "accounts[?name=='$account_name'].id" \
        --output text 2>/dev/null
}

# get account ids
prod_account=$(get_account_id "production")
staging_account=$(get_account_id "staging")
dev_account=$(get_account_id "development")
shared_account=$(get_account_id "shared-services")

# store in environment file
cat > .env << eof
# account ids (generated $(date))
prod_account_id=$prod_account
staging_account_id=$staging_account
dev_account_id=$dev_account
shared_account_id=$shared_account

# management account
management_account_id=$(aws sts get-caller-identity --query account --output text)

# 🇸🇬 singapore additions:
# aws_region=ap-southeast-1
# aws_default_region=ap-southeast-1
# country=singapore
# timezone=asia/singapore
# currency=sgd
eof

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

```bash
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

# 5. manual control tower setup (required first!)
# ⚠️  use root account credentials to log into aws console for this step
# go to aws control tower console and set up landing zone
# 🇸🇬 singapore: go to https://ap-southeast-1.console.aws.amazon.com/controltower/
# 🇸🇬 singapore: select ap-southeast-1 as home region
# use the email addresses from your accounts.ts file

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
```

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
