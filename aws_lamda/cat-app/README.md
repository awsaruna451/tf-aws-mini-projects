# NestJS API on AWS Lambda with Terraform

A Terraform project that deploys a **NestJS** backend application to **AWS Lambda**, exposed via an **API Gateway HTTP API**.

Part of my Terraform + AWS learning journey.

## Architecture

```
Client → API Gateway (HTTP API) → Lambda (NestJS app) → CloudWatch Logs
```

**Resources created:**
- `aws_iam_role` + policy attachment — Lambda execution role with basic execution permissions
- `aws_cloudwatch_log_group` — log group for the Lambda function
- `aws_lambda_function` — runs the NestJS app (Node.js runtime)
- `aws_apigatewayv2_api` — HTTP API (cheaper/simpler than REST API)
- `aws_apigatewayv2_integration` — Lambda proxy integration
- `aws_apigatewayv2_route` — catch-all `$default` route so Nest's own router handles all paths/methods
- `aws_apigatewayv2_stage` — auto-deploying stage named after the environment
- `aws_lambda_permission` — allows API Gateway to invoke the Lambda function

Remote state is stored in S3 (see `backend.tf`), with native S3 locking enabled.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed (v1.5+)
- An AWS account
- AWS CLI configured with credentials (`aws configure`)
- Your NestJS app built and packaged as a Lambda-compatible zip (see below)

## Project Structure

```
.
├── backend.tf          # Remote state config (S3 backend)
├── main.tf               # Lambda, IAM role, API Gateway resources
├── variables.tf            # Input variable definitions
├── outputs.tf                # API endpoint and Lambda outputs
└── README.md
```

## Preparing the Lambda Package

This project expects a pre-built zip at the path set in `lambda_zip_path` (default: `../lambda.zip`), containing your compiled NestJS app with a Lambda handler at `dist/lambda.handler`. Typically this means using a package like `@vendia/serverless-express` or `aws-lambda` adapter to wrap your Nest app, then zipping the `dist/` and `node_modules/` folders.

## Variables

| Name                    | Description                                | Default              |
|--------------------------|----------------------------------------------|------------------------|
| `environment`             | Deployment environment (dev/staging/prod)      | `dev`                    |
| `app_name`                 | Base app name, used in resource naming           | `cat-app`                  |
| `aws_region`                 | AWS region to deploy into                          | `us-east-1`                  |
| `lambda_zip_path`             | Path to the zipped Lambda package                    | `../lambda.zip`                 |
| `handler`                       | Lambda handler (`file.export` form)                     | `dist/lambda.handler`             |
| `runtime`                          | Lambda runtime                                             | `nodejs20.x`                        |
| `memory_size`                        | Memory allocated to the function (MB)                        | `512`                                  |
| `timeout`                               | Function timeout (seconds)                                       | `30`                                      |
| `environment_variables`                   | Extra env vars passed to the Lambda at runtime                      | `{}`                                          |
| `log_retention_days`                         | CloudWatch log retention (days)                                        | `14`                                              |
| `tags`                                          | Extra tags merged into all resources                                       | `{}`                                                  |

## Usage

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd <repo-folder>
   ```

2. **Build and zip your NestJS app**, placing the output at the path set by `lambda_zip_path`.

3. **Update `backend.tf`** with your own S3 state bucket name.

4. **Initialize, plan, and apply**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Get the API endpoint**
   ```bash
   terraform output api_endpoint
   ```

## Cleanup

```bash
terraform destroy
```

## What I Learned

- Deploying a Node.js backend framework (NestJS) to Lambda behind API Gateway
- Using API Gateway HTTP APIs with a Lambda proxy integration and catch-all routing
- Managing Terraform remote state in S3 with native locking
- Structuring reusable Terraform config across environments via variables

