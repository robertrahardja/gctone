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
