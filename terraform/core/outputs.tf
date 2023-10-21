output "lambda_app" {
  value = aws_lambda_function.websockets_app.id
}

output "app_url" {
  value = aws_apigatewayv2_deployment.websockets_agigtw_deployment.id
}

output "websockets_role_arn" {
  value = aws_iam_role.websockets_apigtw_role.arn
}