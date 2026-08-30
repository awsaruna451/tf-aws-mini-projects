# main.tf
# Deploys a NestJS app to Lambda behind an API Gateway HTTP API.
# All resources are named/tagged using var.environment — reuse this same
# config for dev/staging/prod by passing a different -var="environment=..."
# (or a separate .tfvars file per environment).

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Recommended for anything beyond throwaway testing. Point the key at a
  # path unique per environment so state files don't collide.
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "cat-app/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

locals {
  function_name = "${var.app_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.app_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "cat_app" {
  function_name    = local.function_name
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_exec.arn
  memory_size      = var.memory_size
  timeout          = var.timeout

  environment {
    variables = merge(
      { NODE_ENV = var.environment },
      var.environment_variables
    )
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = local.common_tags
}

# --- API Gateway (HTTP API, cheaper/simpler than REST API) ---

resource "aws_apigatewayv2_api" "cat_api_gateway" {
  name          = "${local.function_name}-api"
  protocol_type = "HTTP"
  tags          = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.cat_api_gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cat_app.invoke_arn
  payload_format_version = "2.0"
}

# Catch-all route so Nest's own router handles all paths/methods (/cats, /cats/:id, etc.)
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.cat_api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "cat_api_stage" {
  api_id      = aws_apigatewayv2_api.cat_api_gateway.id
  name        = var.environment
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cat_app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cat_api_gateway.execution_arn}/*/*"
}
