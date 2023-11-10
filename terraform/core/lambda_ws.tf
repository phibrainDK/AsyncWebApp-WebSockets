resource "aws_ecr_repository" "repo_ws" {
  name         = local.ecr_repository_name
  force_delete = true
}

resource "null_resource" "ecr_image_ws" {
  triggers = {
    js_files   = md5(join("", fileset("../../server/ws/", "*.js")))
    json_files = md5(join("", fileset("../../server/ws/", "*.json")))
    dockerfile = md5(file("../../server/ws/Dockerfile"))
    data       = md5(file("../../server/ws/ws_handler.js"))
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.deploy_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.deploy_region}.amazonaws.com&&cd ../../server/ws&&docker build -t ${aws_ecr_repository.repo_ws.repository_url}:${local.ecr_image_ws_tag} .&&docker push ${aws_ecr_repository.repo_ws.repository_url}:${local.ecr_image_ws_tag}"
  }
}

data "aws_ecr_image" "lambda_image_ws" {
  depends_on = [
    null_resource.ecr_image_ws
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_ws_tag
}

resource "aws_iam_role" "lambda_ws" {
  name = "${local.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_ws" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  # To manage conexions via Lambda (check aws_lambda_permission.apigtw_websockets_lambda)
  statement {
    actions = [
      "execute-api:ManageConnections",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_ws" {
  name   = "${local.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_ws.json
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment_ws" {
  role       = aws_iam_role.lambda_ws.id
  policy_arn = aws_iam_policy.lambda_ws.arn
}


resource "aws_lambda_function" "websockets_app" {
  depends_on = [
    null_resource.ecr_image_ws,
    aws_dynamodb_table.dynamo_sessions_db,
  ]
  function_name = "${local.prefix}-be-core"
  role          = aws_iam_role.lambda_ws.arn
  timeout       = 30
  image_uri     = "${aws_ecr_repository.repo_ws.repository_url}@${data.aws_ecr_image.lambda_image_ws.id}"
  package_type  = "Image"
  memory_size   = 512

  environment {
    variables = {
      API_URL_PREFIX      = var.api_url_prefix,
      API_VERSION         = var.api_version,
      DEPLOY_REGION       = var.deploy_region,
      ENV_STAGE           = local.stage,
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.dynamo_sessions_db.name,
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_ws" {
  name              = "/aws/lambda/${aws_lambda_function.websockets_app.function_name}"
  retention_in_days = 0
  lifecycle {
    prevent_destroy = false
  }
}