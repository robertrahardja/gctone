/**
 * APPLICATION STACK
 * 
 * This file defines the main CloudFormation stack that orchestrates the deployment
 * of the Hello World application across different AWS environments. It serves as
 * the primary integration point between the CDK application and the Hello World
 * construct, managing environment-specific configurations and cross-cutting concerns.
 * 
 * Architecture Role:
 * - Acts as the CloudFormation stack boundary for the Hello World application
 * - Integrates the HelloWorldApp construct with environment-specific settings
 * - Manages stack-level concerns like tagging, naming, and resource organization
 * - Provides the deployment unit for CDK synthesis and CloudFormation execution
 * 
 * Multi-Environment Strategy:
 * - Single stack definition used across all environments (dev, staging, shared, prod)
 * - Environment-specific behavior driven by accountconfig parameter
 * - Consistent tagging strategy for cost tracking and resource management
 * - Standardized naming conventions for easy identification and organization
 * 
 * Key Features:
 * - Environment-aware resource configuration
 * - Standardized tagging for governance and cost tracking
 * - Clean separation between infrastructure definition and business logic
 * - Extensible design for additional constructs and resources
 * 
 * Usage:
 * This stack is instantiated by the main CDK app (gctone.ts) for each environment
 * with the appropriate account configuration. Each instance creates a separate
 * CloudFormation stack in the corresponding AWS account.
 */

import { Stack, StackProps, Tags } from "aws-cdk-lib";
import { Construct } from "constructs";
import { helloworldapp } from "../constructs/hello-world-app";
import { accountconfig } from "../config/accounts";

/**
 * Application Stack Props Interface
 * 
 * Extends the standard CDK StackProps to include environment-specific configuration.
 * This interface ensures type safety and provides a clear contract for stack instantiation
 * across different environments and AWS accounts.
 * 
 * Extension Strategy:
 * - Inherits all standard CloudFormation stack properties (env, stackName, description, etc.)
 * - Adds accountconfig parameter for environment-specific behavior
 * - Enables consistent stack creation across multiple environments
 * - Provides type safety for account configuration management
 * 
 * The accountconfig parameter drives:
 * - Resource naming and identification
 * - Environment-specific tagging
 * - Application configuration and behavior
 * - Cost optimization settings
 */
export interface applicationstackprops extends StackProps {
  accountconfig: accountconfig;
}

/**
 * Application Stack Class
 * 
 * The main CloudFormation stack that deploys the Hello World application infrastructure.
 * This stack serves as the deployment boundary and orchestrates the creation of all
 * AWS resources needed for the application in a specific environment.
 * 
 * Stack Responsibilities:
 * - Instantiate and configure the HelloWorldApp construct
 * - Apply environment-specific tagging for governance and cost tracking
 * - Manage stack-level configuration and cross-cutting concerns
 * - Provide a clean deployment unit for CloudFormation operations
 * 
 * Design Principles:
 * - Single Responsibility: Focus on orchestration and configuration
 * - Environment Agnostic: Same code works across all environments
 * - Extensible: Easy to add new constructs and resources
 * - Well-Tagged: Comprehensive tagging for operational excellence
 * 
 * Deployment Strategy:
 * - One stack instance per environment per AWS account
 * - Environment-specific configuration through accountconfig
 * - Consistent naming and tagging across all environments
 * - Clean separation of infrastructure and application logic
 */
export class applicationstack extends Stack {
  /**
   * Application Stack Constructor
   * 
   * Creates the CloudFormation stack and all associated AWS resources
   * for the Hello World application in a specific environment.
   * 
   * @param scope - The parent CDK construct (typically the CDK App)
   * @param id - Unique identifier for this stack instance
   * @param props - Stack properties including environment configuration
   */
  constructor(scope: Construct, id: string, props: applicationstackprops) {
    super(scope, id, props);

    // Extract account configuration for use throughout the stack
    const { accountconfig } = props;

    /**
     * Hello World Application Instantiation
     * 
     * Creates the main HelloWorldApp construct which encapsulates all the
     * AWS resources needed for the serverless Hello World application.
     * The construct receives the account configuration to customize its
     * behavior for the target environment.
     * 
     * Resource Creation:
     * - Lambda functions with environment-specific sizing
     * - HTTP API Gateway with CORS configuration
     * - CloudWatch log groups with appropriate retention
     * - API routes for main endpoint and health checks
     * - CloudFormation outputs for API URLs
     */
    new helloworldapp(this, "helloworldapp", {
      accountconfig,  // Pass environment configuration to the construct
    });

    /**
     * Stack-Level Tagging Strategy
     * 
     * Applies comprehensive tags to all resources in this stack for governance,
     * cost tracking, and operational management. These tags are inherited by
     * all child resources and provide essential metadata for AWS resource management.
     * 
     * Tagging Benefits:
     * - Cost allocation and tracking by environment and project
     * - Resource discovery and filtering in AWS console
     * - Automation and compliance monitoring
     * - Change management and ownership tracking
     * 
     * Tag Categories:
     * - Environment identification for cost segregation
     * - Management tool identification for automation
     * - Project identification for organizational tracking
     */
    
    /**
     * Environment Tag
     * Identifies the deployment environment (dev, staging, shared, prod)
     * for cost allocation and environment-specific operations.
     */
    Tags.of(this).add("environment", accountconfig.environment);
    
    /**
     * Management Tool Tag
     * Identifies that this infrastructure is managed by AWS CDK,
     * helping operations teams understand deployment methodology.
     */
    Tags.of(this).add("managedby", "cdk");
    
    /**
     * Project Tag
     * Identifies the project or initiative for organizational tracking
     * and cost allocation across multiple projects.
     */
    Tags.of(this).add("project", "simplecontroltower");
  }
}
