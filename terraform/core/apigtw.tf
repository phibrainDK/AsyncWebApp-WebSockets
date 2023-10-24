resource "aws_apigatewayv2_api" "websockets_apigtw" {
  name                         = "WebSocketAPI-${local.prefix}"
  protocol_type                = "WEBSOCKET"
  route_selection_expression   = "$request.body.action"
  description                  = "Websockets API - ${local.prefix}"
  tags                         = local.tags
  api_key_selection_expression = "$request.header.x-api-key"
}

resource "aws_apigatewayv2_deployment" "websockets_agigtw_deployment" {
  depends_on = [
    aws_apigatewayv2_api.websockets_apigtw,
    aws_apigatewayv2_route.websockets_route_connect,
    aws_apigatewayv2_route.websockets_route_disconnect,
    aws_apigatewayv2_route.websockets_route_default,
    aws_lambda_permission.apigtw_websockets_lambda,
  ]
  api_id      = aws_apigatewayv2_api.websockets_apigtw.id
  description = "Websockets deployment"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_route.websockets_route_connect),
      jsonencode(aws_apigatewayv2_route.websockets_route_disconnect),
      jsonencode(aws_apigatewayv2_route.websockets_route_default),
    ])))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_integration" "apigtw_integration" {
  depends_on = [
    aws_apigatewayv2_api.websockets_apigtw,
    aws_lambda_function.websockets_app,
  ]
  api_id           = aws_apigatewayv2_api.websockets_apigtw.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.websockets_app.invoke_arn
}


resource "aws_apigatewayv2_stage" "websockets_apigtw_stage" {
  depends_on = [
    aws_cloudwatch_log_group.websockets_group_cloudwatch,
    aws_apigatewayv2_api.websockets_apigtw
  ]
  api_id        = aws_apigatewayv2_api.websockets_apigtw.id
  name          = "${local.prefix}-${local.stage}"
  description   = "${local.prefix} - Websockets Stage "
  deployment_id = aws_apigatewayv2_deployment.websockets_agigtw_deployment.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.websockets_group_cloudwatch.arn
    format          = "{\"requestId\":\"$context.requestId\", \"extendedRequestId\":\"$context.extendedRequestId\"}"
  }
  default_route_settings {
    data_trace_enabled       = "true"
    detailed_metrics_enabled = "true"
    logging_level            = "INFO"
    throttling_burst_limit   = 5
    throttling_rate_limit    = 2
  }
  route_settings {
    route_key                = "$connect"
    data_trace_enabled       = "true"
    detailed_metrics_enabled = "true"
    logging_level            = "INFO"
    throttling_burst_limit   = 5
    throttling_rate_limit    = 2
  }

  route_settings {
    route_key                = "$disconnect"
    data_trace_enabled       = "true"
    detailed_metrics_enabled = "true"
    logging_level            = "INFO"
    throttling_burst_limit   = 5
    throttling_rate_limit    = 2
  }
}

resource "aws_apigatewayv2_route" "websockets_route_connect" {
  depends_on = [
    aws_apigatewayv2_api.websockets_apigtw,
    aws_apigatewayv2_integration.apigtw_integration,
  ]
  api_id    = aws_apigatewayv2_api.websockets_apigtw.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.apigtw_integration.id}"
}

resource "aws_apigatewayv2_route" "websockets_route_disconnect" {
  depends_on = [
    aws_apigatewayv2_api.websockets_apigtw,
    aws_apigatewayv2_integration.apigtw_integration,
  ]
  api_id    = aws_apigatewayv2_api.websockets_apigtw.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.apigtw_integration.id}"
}

resource "aws_apigatewayv2_route" "websockets_route_default" {
  depends_on = [
    aws_apigatewayv2_api.websockets_apigtw,
    aws_apigatewayv2_integration.apigtw_integration,
  ]
  api_id    = aws_apigatewayv2_api.websockets_apigtw.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.apigtw_integration.id}"
}

resource "aws_lambda_permission" "apigtw_websockets_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websockets_app.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "WEBSOCKETS API".
  source_arn = "${aws_apigatewayv2_api.websockets_apigtw.execution_arn}/*/*"
}
