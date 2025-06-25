# AWS SSO Profiles Summary

Generated on: Wed Jun 25 15:05:28 +08 2025

## Created Profiles

| Profile | Account ID | Environment | Role |
|---------|------------|-------------|------|
| tar-dev | 803133978889 | Development | AWSAdministratorAccess |
| tar-staging | 521744733620 | Staging | AWSAdministratorAccess |
| tar-shared | 216665870694 | SharedServices | AWSAdministratorAccess |
| tar-prod | 668427974646 | Production | AWSAdministratorAccess |

## Usage

### CDK Bootstrap
```bash
AWS_PROFILE=tar ./scripts/bootstrap-accounts.sh
```

### Individual Account Access
```bash
aws sts get-caller-identity --profile tar-dev
aws sts get-caller-identity --profile tar-staging
aws sts get-caller-identity --profile tar-shared
aws sts get-caller-identity --profile tar-prod
```

### SSO Login (if needed)
```bash
aws sso login --profile tar-dev
aws sso login --profile tar-staging
aws sso login --profile tar-shared
aws sso login --profile tar-prod
```

## Configuration Files
- AWS Config: ~/.aws/config
- Credentials: ~/.aws/credentials (not used with SSO)
