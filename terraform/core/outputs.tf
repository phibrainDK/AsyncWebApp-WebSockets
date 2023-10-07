output "lambda_app" {
  value = aws_lambda_function.app.id
}

output "app_url" {
  value = aws_api_gateway_deployment.app.invoke_url
}

