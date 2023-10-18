output "lambda_app" {
  value = aws_lambda_function.websockets_app.id
}

output "app_url" {
  value = aws_api_gateway_deployment.websocket_deployment.invoke_url
}
