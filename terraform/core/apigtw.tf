resource "aws_api_gateway_rest_api" "websocket_api" {
  name        = "WebSocketAPI-${local.prefix}"
  description = "WebSocket API for real-time communication"
}

resource "aws_api_gateway_deployment" "websocket_deployment" {
  rest_api_id = aws_api_gateway_rest_api.websocket_api.id
  stage_name  = "${local.stage}-tf"
}


resource "aws_api_gateway_integration" "websocket_integration" {
  depends_on = [
    aws_lambda_function.websockets_app,
    aws_api_gateway_rest_api.websocket_api,
  ]
  rest_api_id             = aws_api_gateway_rest_api.websocket_api.id
  resource_id             = aws_api_gateway_rest_api.websocket_api.root_resource_id
  http_method             = "ANY"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.websockets_app.invoke_arn
}


resource "aws_api_gateway_route" "websocket_route_connect" {
  route_key = "$connect"
  target    = "integrations/${aws_api_gateway_integration.websocket_integration.id}"
  api_id    = aws_api_gateway_rest_api.websocket_api.id
}

resource "aws_api_gateway_route" "websocket_route_disconnect" {
  route_key = "$disconnect"
  target    = "integrations/${aws_api_gateway_integration.websocket_integration.id}"
  api_id    = aws_api_gateway_rest_api.websocket_api.id
}

resource "aws_api_gateway_route" "websocket_route_default" {
  route_key = "$default"
  target    = "integrations/${aws_api_gateway_integration.websocket_integration.id}"
  api_id    = aws_api_gateway_rest_api.websocket_api.id
}

resource "aws_api_gateway_stage" "websocket_stage" {
  stage_name    = "${local.stage}-tf"
  rest_api_id   = aws_api_gateway_rest_api.websocket_api.id
  deployment_id = aws_api_gateway_deployment.websocket_deployment.id
}
