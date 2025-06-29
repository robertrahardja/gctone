/**
 * Health Check Handler Function
 * 
 * Provides a simple health status endpoint for monitoring and load balancing.
 * Returns basic system information and confirms the Lambda is responsive.
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';

interface HealthResponseBody {
  status: string;
  environment: string;
  timestamp: string;
  uptime: number;
}

export const handler = async (
  _event: APIGatewayProxyEvent,
  _context: Context
): Promise<APIGatewayProxyResult> => {
  
  const responseBody: HealthResponseBody = {
    status: 'healthy',                                              // Health status indicator
    environment: process.env.ENVIRONMENT || 'unknown',            // Environment identification
    timestamp: new Date().toISOString(),                          // Current timestamp
    uptime: process.uptime()                                       // Lambda container uptime
  };

  const response: APIGatewayProxyResult = {
    statusCode: 200,                                               // HTTP OK status
    headers: { 
      'Content-Type': 'application/json',                         // JSON response header
      'Access-Control-Allow-Origin': '*'                          // Enable CORS
    },
    body: JSON.stringify(responseBody)
  };

  return response;
};