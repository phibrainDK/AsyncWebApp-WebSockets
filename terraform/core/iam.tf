data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ws_authorizer_role" {
  name = "${local.prefix}-auth-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "ws_authorizer_policy_document" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ws_authorizer_policy" {
  name   = "${local.prefix_auth}-auth-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_authorizer_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ws_authorizer_policy_attachment" {
  role       = aws_iam_role.ws_authorizer_role.id
  policy_arn = aws_iam_policy.ws_authorizer_policy.arn
}







resource "aws_api_gateway_account" "apigtw_account" {
  depends_on = [
    aws_cloudwatch_log_group.websockets_group_cloudwatch,
  ]
  cloudwatch_role_arn = aws_iam_role.websockets_apigtw_role.arn
}

resource "aws_iam_role" "websockets_apigtw_role" {
  depends_on = [
    data.aws_iam_policy_document.assume_role,
  ]
  name               = "${local.prefix}-websockets-flow-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "websockets_apigtw_policy" {
  depends_on = [
    data.aws_iam_policy_document.cloudwatch,
  ]
  name   = "${local.prefix}-websockets-flow-policy"
  policy = data.aws_iam_policy_document.cloudwatch.json
  role   = aws_iam_role.websockets_apigtw_role.id
}
