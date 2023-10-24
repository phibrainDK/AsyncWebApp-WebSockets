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
