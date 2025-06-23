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
