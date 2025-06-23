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
