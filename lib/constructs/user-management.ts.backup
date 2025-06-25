/**
 * IAM Identity Center User Management Construct
 * 
 * Automates the creation and management of IAM Identity Center users for
 * multi-account AWS Control Tower deployments. This construct creates
 * environment-specific users and assigns them to appropriate permission sets.
 */

import { Construct } from 'constructs';
import * as cdk from 'aws-cdk-lib';
import * as identitystore from 'aws-cdk-lib/aws-identitystore';
import * as ssoadmin from 'aws-cdk-lib/aws-ssoadmin';

export interface UserManagementProps {
  /**
   * IAM Identity Center Identity Store ID
   * Can be found in IAM Identity Center console or via:
   * aws sso-admin list-instances
   */
  identityStoreId: string;
  
  /**
   * IAM Identity Center Instance ARN
   * Required for permission set assignments
   */
  instanceArn: string;
  
  /**
   * Base email domain for creating environment-specific users
   * Example: "mycompany.com" will create users like dev@mycompany.com
   */
  baseEmail: string;
  
  /**
   * Account IDs for each environment
   * Used for permission set assignments
   */
  accounts: {
    dev: string;
    staging: string;
    shared: string;
    prod: string;
  };
  
  /**
   * Organization ID for creating permission sets with proper trust policies
   */
  organizationId?: string;
}

export interface EnvironmentUser {
  user: identitystore.CfnUser;
  permissionSet: ssoadmin.CfnPermissionSet;
  assignment: ssoadmin.CfnAccountAssignment;
}

/**
 * User Management Construct
 * 
 * Creates IAM Identity Center users and permission sets for each environment
 * in a Control Tower multi-account setup. Automates the manual process of
 * creating users and assigning permissions.
 */
export class UserManagement extends Construct {
  public readonly users: Record<string, EnvironmentUser> = {};
  
  constructor(scope: Construct, id: string, props: UserManagementProps) {
    super(scope, id);
    
    // Define environments and their configurations
    const environments = [
      { key: 'dev', name: 'Development', accountId: props.accounts.dev },
      { key: 'staging', name: 'Staging', accountId: props.accounts.staging },
      { key: 'shared', name: 'Shared Services', accountId: props.accounts.shared },
      { key: 'prod', name: 'Production', accountId: props.accounts.prod }
    ];
    
    // Create users and permission sets for each environment
    environments.forEach(env => {
      this.users[env.key] = this.createEnvironmentUser(env, props);
    });
  }
  
  /**
   * Creates a complete user setup for an environment
   * Includes user creation, permission set, and account assignment
   */
  private createEnvironmentUser(
    environment: { key: string; name: string; accountId: string },
    props: UserManagementProps
  ): EnvironmentUser {
    
    // Create IAM Identity Center User
    const user = new identitystore.CfnUser(this, `${environment.key}User`, {
      identityStoreId: props.identityStoreId,
      userName: `${environment.key}-admin`,
      displayName: `${environment.name} Administrator`,
      emails: [{
        value: this.generateEmailAddress(props.baseEmail, environment.key),
        type: 'work',
        primary: true
      }],
      name: {
        givenName: environment.name,
        familyName: 'Administrator'
      }
    });
    
    // Create environment-specific permission set
    const permissionSet = new ssoadmin.CfnPermissionSet(this, `${environment.key}PermissionSet`, {
      instanceArn: props.instanceArn,
      name: `${environment.name}AdminAccess`,
      description: `Administrative access for ${environment.name} environment`,
      sessionDuration: 'PT12H', // 12 hours
      inlinePolicy: this.createEnvironmentPolicy(environment.key, props.organizationId)
    });
    
    // Assign user to permission set in target account
    const assignment = new ssoadmin.CfnAccountAssignment(this, `${environment.key}Assignment`, {
      instanceArn: props.instanceArn,
      permissionSetArn: permissionSet.attrPermissionSetArn,
      principalId: user.attrUserId,
      principalType: 'USER',
      targetId: environment.accountId,
      targetType: 'AWS_ACCOUNT'
    });
    
    // Ensure proper dependency order
    assignment.addDependency(user);
    assignment.addDependency(permissionSet);
    
    return { user, permissionSet, assignment };
  }
  
  /**
   * Generates environment-specific email addresses
   * Supports both plus-addressing and subdomain patterns
   */
  private generateEmailAddress(baseEmail: string, environment: string): string {
    if (baseEmail.includes('@')) {
      // Use plus-addressing: user@domain.com -> user+env@domain.com
      const [localPart, domain] = baseEmail.split('@');
      return `${localPart}+${environment}@${domain}`;
    } else {
      // Use subdomain: domain.com -> env@domain.com
      return `${environment}@${baseEmail}`;
    }
  }
  
  /**
   * Creates environment-appropriate IAM policies
   * Production has more restrictive policies than development
   */
  private createEnvironmentPolicy(environment: string, organizationId?: string): string {
    const basePolicy = {
      Version: '2012-10-17',
      Statement: []
    };
    
    // Base administrative permissions
    basePolicy.Statement.push({
      Effect: 'Allow',
      Action: [
        // Core AWS services
        'ec2:*',
        'lambda:*',
        'apigateway:*',
        'cloudformation:*',
        'iam:*',
        's3:*',
        'logs:*',
        'cloudwatch:*',
        // CDK specific
        'ssm:GetParameter*',
        'ssm:PutParameter',
        'ecr:*',
        // Cost and billing (read-only)
        'ce:*',
        'budgets:View*',
        'account:GetAccountInformation'
      ],
      Resource: '*'
    });
    
    // Environment-specific restrictions
    if (environment === 'prod') {
      // Production has additional restrictions
      basePolicy.Statement.push({
        Effect: 'Deny',
        Action: [
          'iam:DeleteRole',
          'iam:DeletePolicy',
          'ec2:TerminateInstances'
        ],
        Resource: '*',
        Condition: {
          StringNotEquals: {
            'aws:RequestedRegion': ['ap-southeast-1', 'us-east-1']
          }
        }
      });
    }
    
    // Cross-account access for CDK (if organization ID provided)
    if (organizationId) {
      basePolicy.Statement.push({
        Effect: 'Allow',
        Action: 'sts:AssumeRole',
        Resource: 'arn:aws:iam::*:role/OrganizationAccountAccessRole',
        Condition: {
          StringEquals: {
            'aws:PrincipalOrgID': organizationId
          }
        }
      });
    }
    
    return JSON.stringify(basePolicy, null, 2);
  }
  
  /**
   * Outputs user information for CLI profile setup
   */
  public getUserOutputs(): Record<string, cdk.CfnOutput> {
    const outputs: Record<string, cdk.CfnOutput> = {};
    
    Object.entries(this.users).forEach(([env, userInfo]) => {
      outputs[`${env}UserId`] = new cdk.CfnOutput(this, `${env}UserIdOutput`, {
        value: userInfo.user.attrUserId,
        description: `IAM Identity Center User ID for ${env} environment`,
        exportName: `UserManagement-${env}-UserId`
      });
      
      outputs[`${env}PermissionSetArn`] = new cdk.CfnOutput(this, `${env}PermissionSetArnOutput`, {
        value: userInfo.permissionSet.attrPermissionSetArn,
        description: `Permission Set ARN for ${env} environment`,
        exportName: `UserManagement-${env}-PermissionSetArn`
      });
    });
    
    return outputs;
  }
}

/**
 * Helper class for managing existing manual users
 * Use this when you already have manually created users and want to manage them
 */
export class ExistingUserManager extends Construct {
  
  constructor(scope: Construct, id: string, props: {
    identityStoreId: string;
    instanceArn: string;
    existingUsers: Record<string, { userId: string; email: string }>;
    accounts: Record<string, string>;
  }) {
    super(scope, id);
    
    // Create outputs for existing users to help with CLI setup
    Object.entries(props.existingUsers).forEach(([env, userInfo]) => {
      new cdk.CfnOutput(this, `${env}ExistingUserInfo`, {
        value: JSON.stringify({
          userId: userInfo.userId,
          email: userInfo.email,
          accountId: props.accounts[env]
        }),
        description: `Existing user information for ${env} environment CLI setup`
      });
    });
  }
}