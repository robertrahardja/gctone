/**
 * ACCOUNTS CONFIGURATION FILE
 * 
 * This file defines the multi-environment AWS account structure for AWS Control Tower.
 * It provides centralized configuration for deploying applications across different 
 * environments (dev, staging, shared, prod) with environment-specific settings.
 * 
 * Purpose:
 * - Defines account configurations for AWS Control Tower workload accounts
 * - Provides environment-specific resource sizing for cost optimization
 * - Maps email addresses to AWS accounts for Control Tower setup
 * - Centralizes application configuration (messages, timeouts, memory)
 * 
 * Usage:
 * - Used by CDK stacks to deploy resources with environment-appropriate settings
 * - Controls Lambda memory allocation and timeout based on environment
 * - Provides email mapping for AWS Control Tower account creation
 * - Enables consistent tagging and resource naming across environments
 */

/**
 * Interface defining the configuration structure for each AWS workload account.
 * 
 * This interface ensures type safety and consistency across all environment configurations.
 * Each property controls specific aspects of the deployed infrastructure:
 * 
 * - name: Human-readable account name for identification and tagging
 * - email: Email address used for AWS account creation in Control Tower
 * - environment: Environment type that determines deployment behavior
 * - helloworldmessage: Custom message returned by the Lambda function
 * - memorysize: Lambda memory allocation in MB (cost optimization)
 * - timeout: Lambda timeout in seconds (performance vs cost balance)
 */
export interface accountconfig {
  name: string;
  email: string;
  environment: "prod" | "staging" | "dev" | "shared";
  helloworldmessage: string;
  memorysize: number;
  timeout: number;
}

/**
 * Workload account configurations for AWS Control Tower multi-environment setup.
 * 
 * This Record defines four separate AWS accounts, each with environment-specific settings
 * optimized for different stages of the software development lifecycle. The configuration
 * implements a cost-optimization strategy where development environments use minimal resources
 * and production environments use full resources.
 * 
 * Resource Scaling Strategy:
 * - Development: Minimal resources (128MB, 10s timeout) for cost savings
 * - Staging: Moderate resources (256MB, 15s timeout) for testing
 * - Shared: Moderate resources (256MB, 15s timeout) for shared services
 * - Production: Full resources (512MB, 30s timeout) for performance
 * 
 * Email Strategy:
 * Uses Gmail alias pattern (email+alias@gmail.com) to create separate AWS accounts
 * while using a single email address. This is a common pattern for Control Tower setup.
 */
export const accounts: Record<string, accountconfig> = {
  /**
   * Development Environment Configuration
   * 
   * Optimized for cost savings with minimal resources. Used for:
   * - Developer testing and experimentation
   * - Feature development and debugging
   * - Cost-sensitive workloads
   * 
   * Resource Allocation:
   * - Memory: 128MB (minimum for Node.js Lambda)
   * - Timeout: 10 seconds (sufficient for simple operations)
   * - Purpose: Cost optimization over performance
   */
  dev: {
    name: "development",
    email: "testawsrahardja+dev@gmail.com", // update with ./scripts/sync-account-emails.sh
    environment: "dev",
    helloworldmessage: "hello from development! 💻",
    // 🇸🇬 singapore version: "hello from singapore development! 🇸🇬💻",
    memorysize: 128, // minimal for cost optimization
    timeout: 10,
  },
  /**
   * Staging Environment Configuration
   * 
   * Pre-production environment for testing and validation. Used for:
   * - Integration testing
   * - User acceptance testing
   * - Performance testing with realistic data
   * 
   * Resource Allocation:
   * - Memory: 256MB (balanced for testing scenarios)
   * - Timeout: 15 seconds (allows for more complex operations)
   * - Purpose: Balance between cost and production-like performance
   */
  staging: {
    name: "staging",
    email: "testawsrahardja+staging@gmail.com", // update with ./scripts/sync-account-emails.sh
    environment: "staging",
    helloworldmessage: "hello from staging! 🧪",
    // 🇸🇬 singapore version: "hello from singapore staging! 🇸🇬🧪",
    memorysize: 256,
    timeout: 15,
  },
  /**
   * Shared Services Environment Configuration
   * 
   * Dedicated account for shared infrastructure and services. Used for:
   * - Shared databases and storage
   * - Common utilities and tools
   * - Cross-environment resources
   * 
   * Resource Allocation:
   * - Memory: 256MB (sufficient for utility functions)
   * - Timeout: 15 seconds (adequate for service operations)
   * - Purpose: Stable resources for shared components
   */
  shared: {
    name: "shared-services",
    email: "testawsrahardja+shared@gmail.com", // update with ./scripts/sync-account-emails.sh
    environment: "shared",
    helloworldmessage: "hello from shared services! 🔧",
    // 🇸🇬 singapore version: "hello from singapore shared services! 🇸🇬🔧",
    memorysize: 256,
    timeout: 15,
  },
  /**
   * Production Environment Configuration
   * 
   * Live production environment with full resources. Used for:
   * - Customer-facing applications
   * - Business-critical workloads
   * - High-performance requirements
   * 
   * Resource Allocation:
   * - Memory: 512MB (maximum performance for production workloads)
   * - Timeout: 30 seconds (handles complex operations and high load)
   * - Purpose: Maximum performance and reliability
   */
  prod: {
    name: "production",
    email: "testawsrahardja+prod@gmail.com", // update with ./scripts/sync-account-emails.sh
    environment: "prod",
    helloworldmessage: "hello from production! 🚀",
    // 🇸🇬 singapore version: "hello from singapore production! 🇸🇬🚀",
    memorysize: 512,
    timeout: 30,
  },
};

/**
 * AWS Control Tower Core Account Email Mappings
 * 
 * These are the foundational accounts that AWS Control Tower automatically creates
 * and manages as part of the Landing Zone setup. These accounts provide governance,
 * security, and compliance capabilities across all workload accounts.
 * 
 * Account Purposes:
 * - Management: Root account where Control Tower is deployed, manages all other accounts
 * - Audit: Dedicated account for security auditing and compliance monitoring
 * - Log Archive: Centralized logging account for all CloudTrail and security logs
 * 
 * Email Requirements:
 * - Each account requires a unique email address for AWS account creation
 * - Using Gmail aliases allows single email management while meeting AWS requirements
 * - These emails will receive AWS billing and security notifications
 * 
 * Security Note:
 * These core accounts are managed by AWS Control Tower and should not be used
 * for application workloads. They provide governance over workload accounts.
 */
export const core_accounts = {
  /**
   * Management Account (Root)
   * 
   * The primary AWS account where Control Tower is installed and operated.
   * This account manages all other accounts in the organization and should
   * be used only for governance and billing consolidation.
   * 
   * Responsibilities:
   * - Control Tower management and configuration
   * - Organization-wide billing and cost management
   * - Cross-account IAM role management
   * - Service Control Policy (SCP) management
   */
  management: "testawsrahardja@gmail.com", // update with ./scripts/sync-account-emails.sh
  
  /**
   * Audit Account
   * 
   * Dedicated account for security auditing and compliance monitoring.
   * AWS Control Tower automatically configures this account with read-only
   * access to all other accounts for security monitoring purposes.
   * 
   * Responsibilities:
   * - Security monitoring and alerting
   * - Compliance reporting and auditing
   * - Cross-account security assessment
   * - Detective controls and investigation
   */
  audit: "testawsrahardjaaudit@gmail.com", // update with ./scripts/sync-account-emails.sh
  
  /**
   * Log Archive Account
   * 
   * Centralized logging account that receives and stores CloudTrail logs,
   * Config logs, and other security-relevant logs from all accounts in
   * the organization. Provides long-term log retention and analysis.
   * 
   * Responsibilities:
   * - Long-term log storage and retention
   * - CloudTrail log aggregation from all accounts
   * - AWS Config compliance data storage
   * - Security log analysis and forensics
   */
  logarchive: "testawsrahardjalogs@gmail.com", // update with ./scripts/sync-account-emails.sh
};
