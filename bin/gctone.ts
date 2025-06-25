#!/usr/bin/env node

/**
 * CDK APPLICATION ENTRY POINT
 * 
 * This is the main entry point for the AWS CDK application that deploys the Hello World
 * serverless application across multiple AWS accounts using AWS Control Tower governance.
 * This file orchestrates the creation of CloudFormation stacks for each environment
 * with appropriate configurations and AWS account targeting.
 * 
 * Architecture Overview:
 * - Multi-account deployment using AWS Control Tower accounts
 * - Environment-specific stack creation (dev, staging, shared, prod)
 * - Account-aware resource targeting through environment variables
 * - Centralized configuration management through accounts.ts
 * - Global tagging strategy for governance and cost tracking
 * 
 * Deployment Strategy:
 * - Each environment gets its own CloudFormation stack
 * - Each stack is deployed to its designated AWS account
 * - Account IDs are resolved through environment variables
 * - Consistent naming and tagging across all environments
 * 
 * Environment Variable Dependencies:
 * - DEV_ACCOUNT_ID: AWS account ID for development environment
 * - STAGING_ACCOUNT_ID: AWS account ID for staging environment
 * - SHARED_ACCOUNT_ID: AWS account ID for shared services
 * - PROD_ACCOUNT_ID: AWS account ID for production environment
 * - CDK_DEFAULT_ACCOUNT: Fallback account ID for local development
 * - CDK_DEFAULT_REGION: AWS region for all deployments (default: us-east-1)
 * 
 * Control Tower Integration:
 * - Designed to work with AWS Control Tower multi-account setup
 * - Supports cross-account deployment through CDK bootstrapping
 * - Follows AWS Control Tower best practices for account separation
 * - Enables centralized governance and compliance monitoring
 * 
 * Usage:
 * - `cdk synth`: Generate CloudFormation templates for all environments
 * - `cdk deploy`: Deploy all stacks (requires appropriate AWS credentials)
 * - `cdk deploy helloworld-dev`: Deploy only the development environment
 * - `cdk destroy`: Remove all deployed resources
 */

import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { applicationstack } from "../lib/stacks/application-stack";
import { accounts } from "../lib/config/accounts";

/**
 * CDK Application Instance Creation
 * 
 * Creates the root CDK application instance that serves as the container
 * for all CloudFormation stacks. This app instance manages the synthesis
 * and deployment lifecycle for the entire multi-environment application.
 */
const app = new cdk.App();

/**
 * Multi-Environment Stack Deployment Loop
 * 
 * Iterates through all configured environments and creates a separate CloudFormation
 * stack for each one. Each stack is targeted at a specific AWS account and configured
 * with environment-appropriate settings from the accounts configuration.
 * 
 * Deployment Pattern:
 * - One stack per environment (dev, staging, shared, prod)
 * - Each stack deployed to its designated AWS account
 * - Environment-specific naming and configuration
 * - Consistent structure across all environments
 * 
 * Account Resolution Strategy:
 * - Primary: Environment-specific variables (DEV_ACCOUNT_ID, PROD_ACCOUNT_ID, etc.)
 * - Fallback: CDK default account for local development
 * - Region: CDK default region with us-east-1 fallback
 * 
 * Stack Naming Convention:
 * - Format: helloworld-{environment}
 * - Examples: helloworld-dev, helloworld-staging, helloworld-prod
 * - Enables easy identification and targeted deployment
 */
Object.entries(accounts).forEach(([key, accountconfig]) => {
  /**
   * Individual Environment Stack Creation
   * 
   * Creates a CloudFormation stack for a specific environment with:
   * - Environment-specific account targeting
   * - Standardized naming conventions
   * - Comprehensive configuration from accounts.ts
   * - Regional deployment settings
   * 
   * @param key - Environment key (dev, staging, shared, prod)
   * @param accountconfig - Environment-specific configuration object
   */
  new applicationstack(app, `helloworld-${key}`, {
    accountconfig: accountconfig,  // Pass environment configuration to stack

    /**
     * AWS Environment Configuration
     * 
     * Specifies the target AWS account and region for stack deployment.
     * Uses environment variables to enable account-specific deployment
     * while maintaining code reusability across environments.
     */
    env: {
      /**
       * Account ID Resolution
       * 
       * Resolves the target AWS account ID using environment variables:
       * - DEV_ACCOUNT_ID for development environment
       * - STAGING_ACCOUNT_ID for staging environment
       * - SHARED_ACCOUNT_ID for shared services environment
       * - PROD_ACCOUNT_ID for production environment
       * - CDK_DEFAULT_ACCOUNT as fallback for local development
       */
      account:
        process.env[`${key.toUpperCase()}_ACCOUNT_ID`] ||
        process.env.CDK_DEFAULT_ACCOUNT,

      /**
       * Region Configuration
       * 
       * Uses CDK_DEFAULT_REGION environment variable or defaults to us-east-1.
       * For Singapore deployment, change default to "ap-southeast-1"
       */
      region: process.env.CDK_DEFAULT_REGION || "us-east-1",
      // 🇸🇬 Singapore deployment: change default to "ap-southeast-1"
    },

    /**
     * Stack Metadata
     * 
     * Provides human-readable information about the stack purpose
     * and environment for CloudFormation console display.
     */
    description: `Hello World application for ${accountconfig.name} environment`,
    // 🇸🇬 Singapore customization: add "(Singapore)" to description

    /**
     * Stack Name Override
     * 
     * Explicitly sets the CloudFormation stack name for consistent
     * naming across environments and easy identification.
     */
    stackName: `helloworld-${key}`,
  });
});

/**
 * Global Application-Level Tagging
 * 
 * Applies tags at the CDK application level, ensuring all stacks and resources
 * inherit these fundamental organizational tags. These tags provide the foundation
 * for cross-environment governance, cost tracking, and operational management.
 * 
 * Tagging Strategy:
 * - Applied at the app level for universal inheritance
 * - Complemented by stack-level and resource-level tags
 * - Designed for AWS Cost Explorer and Resource Groups
 * - Supports organizational reporting and automation
 * 
 * Tag Inheritance:
 * - All stacks inherit these tags automatically
 * - Individual stacks can add environment-specific tags
 * - Resources inherit from both app and stack levels
 * - Creates a hierarchical tagging structure
 */

/**
 * Management Tool Identification Tag
 * 
 * Identifies that all resources in this application are managed by AWS CDK.
 * This helps operations teams understand the deployment methodology and
 * automation approach for maintenance and troubleshooting.
 */
cdk.Tags.of(app).add("managedby", "cdk");

/**
 * Project Identification Tag
 * 
 * Associates all resources with the Simple Control Tower project for
 * organizational tracking, cost allocation, and resource management.
 * This enables project-level reporting and governance.
 */
cdk.Tags.of(app).add("project", "simplecontroltower");

/**
 * Singapore Regional Customization Tags (Optional)
 * 
 * Additional tags for Singapore-specific deployments that provide
 * regional identification and compliance tracking. Uncomment these
 * tags when deploying in Singapore region for enhanced organization.
 * 
 * Benefits:
 * - Regional cost tracking and analysis
 * - Compliance reporting for Singapore regulations
 * - Currency-specific financial reporting
 * - Geographic resource organization
 */
// 🇸🇬 Singapore deployment additions:
cdk.Tags.of(app).add("region", "ap-southeast-1");     // AWS region identification
cdk.Tags.of(app).add("country", "singapore");         // Country-specific compliance
cdk.Tags.of(app).add("currency", "sgd");              // Currency for cost tracking
