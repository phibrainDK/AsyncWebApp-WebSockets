resource "aws_dynamodb_table" "dynamo_sessions_db" {
  name         = "WebSocket-${local.prefix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"
  attribute {
    name = "connectionId"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

