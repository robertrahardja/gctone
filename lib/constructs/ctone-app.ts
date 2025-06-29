/**
 * CTONE APPLICATION CONSTRUCT
 * 
 * This file defines a reusable CDK construct that creates a complete serverless "CTone"
 * application optimized for cost efficiency and multi-environment deployment. The construct
 * demonstrates modern AWS serverless best practices while maintaining minimal operational overhead.
 * 
 * Architecture Overview:
 * - HTTP API Gateway v2 (70% cheaper than REST API)
 * - Lambda Functions with ARM64 architecture (20% cheaper than x86)
 * - CloudWatch Logs with environment-specific retention policies
 * - CORS-enabled API with health check endpoint
 * - Environment-specific resource sizing for cost optimization
 * 
 * Key Features:
 * - Cost-optimized serverless architecture
 * - Environment-aware resource allocation
 * - Built-in health monitoring
 * - Cross-origin resource sharing (CORS) support
 * - Structured logging and monitoring
 * - Infrastructure as Code best practices
 * 
 * Usage:
 * This construct is instantiated by the ApplicationStack for each environment
 * (dev, staging, shared, prod) with environment-specific configurations from
 * the accounts.ts file.
 * 
 * Cost Optimization Features:
 * - HTTP API instead of REST API (significant cost savings)
 * - ARM64 Lambda architecture (Graviton processors)
 * - Environment-specific memory allocation
 * - Optimized log retention policies
 * - RemovalPolicy.DESTROY for easy cleanup
 */

import { Construct } from "constructs";
import {
  aws_lambda as lambda,
  aws_lambda_nodejs as nodejs,
  aws_apigatewayv2 as apigatewayv2,
  aws_apigatewayv2_integrations as integrations,
  aws_logs as logs,
  CfnOutput,
  Duration,
  RemovalPolicy,
} from "aws-cdk-lib";
import { accountconfig } from "../config/accounts";

/**
 * Props interface for the CToneApp construct.
 * 
 * This interface defines the required configuration for instantiating the CToneApp construct.
 * It follows CDK best practices by accepting an account configuration object that contains
 * all environment-specific settings needed to deploy the application appropriately.
 * 
 * The accountconfig parameter drives:
 * - Lambda memory allocation and timeout settings
 * - Environment-specific messaging and identification
 * - Log retention policies based on environment type
 * - Resource naming and tagging strategies
 */
export interface ctoneappprops {
  accountconfig: accountconfig;
}

/**
 * CToneApp Construct Class
 * 
 * A reusable CDK construct that creates a complete serverless CTone application
 * with cost optimization and environment-specific configuration. This construct
 * encapsulates all the AWS resources needed for a basic web API including:
 * 
 * Public Properties:
 * - api: The HTTP API Gateway endpoint (exposed for cross-stack references)
 * - lambda: The main Lambda function (exposed for additional configuration)
 * 
 * Resources Created:
 * - CloudWatch Log Group with environment-specific retention
 * - Main Lambda Function with inline Node.js code
 * - HTTP API Gateway with CORS configuration
 * - Health check Lambda Function for monitoring
 * - API routes for main endpoint (/) and health (/health)
 * - CloudFormation outputs for API URLs
 * 
 * Design Principles:
 * - Environment-aware resource allocation
 * - Cost optimization through ARM64 and HTTP API
 * - Built-in monitoring and health checks
 * - CORS support for web applications
 * - Clean separation of concerns
 */
export class ctoneapp extends Construct {
  /**
   * The HTTP API Gateway instance.
   * Exposed as public readonly to allow other stacks or constructs
   * to reference this API (e.g., for custom domain names, additional routes).
   */
  public readonly api: apigatewayv2.HttpApi;
  
  /**
   * The main Lambda function instance.
   * Exposed as public readonly to allow additional configuration
   * (e.g., event sources, permissions, environment variables).
   */
  public readonly lambda: lambda.IFunction;

  /**
   * CToneApp Constructor
   * 
   * Creates all AWS resources needed for the CTone application with
   * environment-specific configuration. The constructor follows a logical
   * order: logging setup, compute resources, API gateway, and outputs.
   * 
   * @param scope - The parent CDK construct (typically a Stack)
   * @param id - Unique identifier for this construct instance
   * @param props - Configuration object containing account settings
   */
  constructor(scope: Construct, id: string, props: ctoneappprops) {
    super(scope, id);

    // Extract account configuration for use throughout the construct
    const { accountconfig } = props;

    /**
     * CloudWatch Log Group Creation
     * 
     * Creates a dedicated log group for the Lambda function with environment-specific
     * retention policies to optimize costs while maintaining appropriate audit trails.
     * 
     * Cost Optimization Strategy:
     * - Production: 1 month retention for compliance and debugging
     * - Non-Production: 1 week retention to minimize storage costs
     * 
     * Features:
     * - Environment-specific naming for easy identification
     * - RemovalPolicy.DESTROY for clean teardown during development
     * - Explicit log group creation (prevents default indefinite retention)
     */
    const loggroup = new logs.LogGroup(this, "ctoneloggroup", {
      logGroupName: `/aws/lambda/ctone-${accountconfig.environment}`,
      retention:
        accountconfig.environment === "prod"
          ? logs.RetentionDays.ONE_MONTH    // Production: longer retention for audit
          : logs.RetentionDays.ONE_WEEK,    // Dev/Staging: shorter retention for cost
      removalPolicy: RemovalPolicy.DESTROY, // Enables clean infrastructure teardown
    });

    /**
     * Main Lambda Function Creation
     * 
     * Creates the primary Lambda function that handles incoming API requests.
     * This function uses Node.js 22 runtime with ARM64 architecture for optimal
     * cost-performance balance and includes comprehensive request/response handling.
     * 
     * Performance Optimizations:
     * - ARM64 architecture (Graviton processors) for 20% cost savings
     * - Environment-specific memory allocation from account configuration
     * - Environment-specific timeout settings for cost vs performance balance
     * 
     * Function Capabilities:
     * - JSON request/response handling with proper CORS headers
     * - Environment identification and metadata exposure
     * - Request logging for debugging and monitoring
     * - Lambda context information for operational insights
     * 
     * Security Features:
     * - CORS headers for secure cross-origin requests
     * - Structured error handling and response formatting
     * - No sensitive information exposure in responses
     */
    this.lambda = new nodejs.NodejsFunction(this, "ctonefunction", {
      runtime: lambda.Runtime.NODEJS_22_X,  // Latest LTS Node.js for security and performance
      entry: "lib/lambda/main-handler.ts",   // TypeScript source file
      handler: "handler",                    // Export name from TypeScript file
      // Lambda environment variables for runtime configuration
      environment: {
        ENVIRONMENT: accountconfig.environment,     // Environment type for internal logic
        ACCOUNT_NAME: accountconfig.name,           // Account name for identification
        CTONE_MESSAGE: accountconfig.ctonemessage, // Custom environment message
      },
      description: `CTone Lambda for ${accountconfig.name} environment`, // CloudFormation description
      timeout: Duration.seconds(accountconfig.timeout),      // Environment-specific timeout
      memorySize: accountconfig.memorysize,                  // Environment-specific memory allocation
      logGroup: loggroup,                                    // Link to pre-created log group
      architecture: lambda.Architecture.ARM_64,             // ARM64 for 20% cost savings (Graviton)
      bundling: {
        minify: true,                                        // Minify TypeScript output for smaller bundle
        sourceMap: false,                                    // Disable source maps for production
        target: "es2022",                                    // Target modern JavaScript for better performance
      },
    });

    /**
     * HTTP API Gateway Creation (Cost-Optimized Choice)
     * 
     * Creates an HTTP API Gateway v2 instance instead of REST API for significant cost savings
     * (up to 70% cheaper). HTTP APIs are ideal for Lambda proxy integrations and provide
     * built-in CORS support with lower latency than REST APIs.
     * 
     * Cost Benefits:
     * - HTTP API pricing is ~70% lower than REST API
     * - Built-in CORS reduces complexity and latency
     * - Automatic request/response transformations
     * - Native Lambda proxy integration
     * 
     * Security Features:
     * - CORS preflight configuration for web applications
     * - Configurable allowed origins, methods, and headers
     * - Cache control for preflight responses
     */
    this.api = new apigatewayv2.HttpApi(this, "ctoneapi", {
      apiName: `CTone API - ${accountconfig.environment}`,     // Environment-specific naming
      description: `CTone HTTP API for ${accountconfig.name} environment`, // CloudFormation description
      corsPreflight: {
        allowOrigins: ["*"],                           // Allow all origins (customize for production)
        allowMethods: [
          apigatewayv2.CorsHttpMethod.GET,            // Enable GET requests
          apigatewayv2.CorsHttpMethod.POST,           // Enable POST requests
        ],
        allowHeaders: ["Content-Type", "Authorization"], // Standard headers for web apps
        maxAge: Duration.days(1),                      // Cache preflight responses for 24 hours
      },
    });

    /**
     * Main API Route Configuration
     * 
     * Creates the primary route for the CTone application at the root path (/).
     * Uses HTTP Lambda integration for seamless request/response handling between
     * API Gateway and Lambda function.
     * 
     * Route Features:
     * - Root path (/) for simple access
     * - GET method for standard web requests
     * - Lambda proxy integration for automatic request/response handling
     * - No custom authorizers (public endpoint)
     */
    this.api.addRoutes({
      path: "/",                                      // Root path endpoint
      methods: [apigatewayv2.HttpMethod.GET],        // HTTP GET method only
      integration: new integrations.HttpLambdaIntegration(
        "rootintegration",                           // Integration identifier
        this.lambda,                                 // Target Lambda function
      ),
    });

    /**
     * Health Check Lambda Function
     * 
     * Creates a dedicated Lambda function for application health monitoring.
     * This function is intentionally lightweight and separate from the main
     * application logic to provide reliable health status even if the main
     * function has issues.
     * 
     * Design Principles:
     * - Minimal resource allocation (128MB) for cost efficiency
     * - Fast response time (10s timeout) for monitoring systems
     * - Simple logic with minimal dependencies
     * - Consistent response format for automated monitoring
     * 
     * Monitoring Benefits:
     * - Load balancer health checks
     * - Application monitoring systems
     * - Automated alerting and recovery
     * - Service discovery health status
     */
    const healthlambda = new nodejs.NodejsFunction(this, "healthfunction", {
      runtime: lambda.Runtime.NODEJS_22_X,          // Consistent runtime with main function
      entry: "lib/lambda/health-handler.ts",        // TypeScript source file
      handler: "handler",                           // Export name from TypeScript file
      environment: {
        ENVIRONMENT: accountconfig.environment,     // Environment identification
      },
      timeout: Duration.seconds(10),                 // Short timeout for quick health checks
      memorySize: 128,                               // Minimal memory allocation for cost efficiency
      architecture: lambda.Architecture.ARM_64,     // ARM64 for cost optimization
      bundling: {
        minify: true,                                // Minify TypeScript output for smaller bundle
        sourceMap: false,                            // Disable source maps for production
        target: "es2022",                            // Target modern JavaScript for better performance
      },
    });

    /**
     * Health Check API Route Configuration
     * 
     * Creates a dedicated health endpoint at /health for monitoring systems.
     * This route is connected to the lightweight health check Lambda function
     * and follows standard health check endpoint conventions.
     * 
     * Monitoring Integration:
     * - Standard /health path used by most monitoring tools
     * - GET method for simple HTTP health checks
     * - Separate Lambda ensures health status even if main app fails
     * - Fast response for load balancer health checks
     */
    this.api.addRoutes({
      path: "/health",                               // Standard health check endpoint path
      methods: [apigatewayv2.HttpMethod.GET],       // HTTP GET method for health checks
      integration: new integrations.HttpLambdaIntegration(
        "healthintegration",                         // Integration identifier
        healthlambda,                                // Target health check Lambda function
      ),
    });

    /**
     * CloudFormation Stack Outputs
     * 
     * Creates CloudFormation outputs for the API endpoints to enable:
     * - Cross-stack references in larger architectures
     * - Easy access to endpoint URLs for testing and integration
     * - Automated deployment pipeline integration
     * - Infrastructure documentation and discovery
     * 
     * Output Strategy:
     * - Main API URL with cross-stack export for reuse
     * - Health check URL for monitoring system configuration
     * - Environment-specific naming for multi-environment deployments
     */
    
    /**
     * Main API Endpoint Output
     * 
     * Exports the main API Gateway endpoint URL for external access and cross-stack references.
     * The exportName enables other CloudFormation stacks to import this value using Fn::ImportValue.
     */
    new CfnOutput(this, "apiurl", {
      value: this.api.apiEndpoint,                                        // API Gateway endpoint URL
      description: `CTone API URL for ${accountconfig.environment}`, // Human-readable description
      exportName: `ctoneapiurl-${accountconfig.environment}`,        // Cross-stack export name
    });

    /**
     * Health Check Endpoint Output
     * 
     * Provides the health check endpoint URL for monitoring systems and load balancers.
     * This output is used by automated deployment scripts and monitoring configurations.
     */
    new CfnOutput(this, "healthcheckurl", {
      value: `${this.api.apiEndpoint}/health`,                            // Health check endpoint URL
      description: `Health check URL for ${accountconfig.environment}`,   // Human-readable description
    });
  }
}
