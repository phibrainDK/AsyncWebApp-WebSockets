resource "aws_cloudwatch_log_group" "websockets_group_cloudwatch" {
  name              = "/aws/websockets/${local.prefix}-cloudwatch-log-group"
  retention_in_days = 0
  lifecycle {
    prevent_destroy = false
  }
}
