resource "aws_dynamodb_table" "dynamo_sessions_db" {
  name         = "WebSocket-${local.prefix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "connectionId"

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "connectionId"
    type = "S"
  }

  attribute {
    name = "data"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "ConnectionIdIndex"
    hash_key        = "connectionId"
    range_key       = "data"
    projection_type = "ALL"
  }
}

