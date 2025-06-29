/**
 * Main Lambda Handler Function
 * 
 * Processes incoming HTTP requests and returns a JSON response with
 * environment information, metadata, and operational details.
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';

interface ResponseMetadata {
  remainingTime: number;
  memoryLimit: string;
  architecture: string;
  nodeVersion: string;
}

interface ResponseBody {
  message: string;
  environment: string;
  account: string;
  timestamp: string;
  requestId: string;
  region: string;
  version: string;
  runtime: string;
  metadata: ResponseMetadata;
}

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  // Log incoming request for debugging and monitoring
  console.log('event received:', JSON.stringify(event, null, 2));
  
  // Construct response body with proper typing
  const responseBody: ResponseBody = {
    // Environment identification
    message: process.env.CTONE_MESSAGE || 'CTone!',        // Custom environment message from env var
    environment: process.env.ENVIRONMENT || 'unknown',                 // Environment type (dev/staging/prod)
    account: process.env.ACCOUNT_NAME || 'unknown',                    // Account name for identification
    
    // Request tracking and timing
    timestamp: new Date().toISOString(),                               // ISO timestamp for request
    requestId: context.awsRequestId,                                   // Unique request identifier
    region: process.env.AWS_REGION || 'unknown',                      // AWS region information
    
    // Application metadata
    version: '1.0.0',                                                  // Application version
    runtime: 'nodejs22.x',                                            // Lambda runtime information
    
    // 🇸🇬 Singapore regional customization (commented for universal use)
    // location: {
    //   country: 'singapore',
    //   region: 'ap-southeast-1', 
    //   timezone: 'asia/singapore',
    //   localtime: new Date().toLocaleString('en-sg', {
    //     timeZone: 'asia/singapore'
    //   })
    // },
    
    // Lambda execution metadata for monitoring
    metadata: {
      remainingTime: context.getRemainingTimeInMillis(),             // Execution time remaining
      memoryLimit: context.memoryLimitInMB,                          // Allocated memory limit
      architecture: process.arch,                                    // CPU architecture (arm64)
      nodeVersion: process.version                                   // Node.js version
    }
  };
  
  // Construct standardized HTTP response with CORS headers
  const response: APIGatewayProxyResult = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',                           // Enable CORS for web apps
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',        // Allowed HTTP methods
      'Access-Control-Allow-Headers': 'Content-Type, Authorization', // Allowed headers
    },
    body: JSON.stringify(responseBody, null, 2)  // Pretty-printed JSON for readability
  };
  
  return response;
};// CI/CD pipeline test - Sun Jun 29 15:31:27 +08 2025
