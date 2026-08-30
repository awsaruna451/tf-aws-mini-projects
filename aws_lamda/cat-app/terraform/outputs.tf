output "api_endpoint" {
  description = "Invoke this URL to hit your API, e.g. POST {api_endpoint}/cats"
  value       = aws_apigatewayv2_stage.cat_api_stage.invoke_url
}

output "lambda_function_name" {
  value = aws_lambda_function.cat_app.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.cat_app.arn
}

output "environment" {
  value = var.environment
}
