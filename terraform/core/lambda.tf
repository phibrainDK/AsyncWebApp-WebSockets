resource "aws_ecr_repository" "repo" {
  name         = local.ecr_repository_name
  force_delete = true
}

resource "null_resource" "ecr_image" {
  triggers = {
    js_files   = md5(join("", fileset("../../server/", "*.js")))
    json_files = md5(join("", fileset("../../server/", "*.json")))
    dockerfile = md5(file("../../server/Dockerfile"))
    # data       = md5(file("../../server/handler.js"))
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.deploy_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.deploy_region}.amazonaws.com&&cd ../../server&&docker build -t ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag} .&&docker push ${aws_ecr_repository.repo.repository_url}:${local.ecr_image_tag}"
  }
}

data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag

}

resource "aws_iam_role" "lambda" {
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

data "aws_iam_policy_document" "lambda" {
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
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.lambda.arn
}


resource "aws_lambda_function" "websockets_app" {
  depends_on = [
    null_resource.ecr_image,
    aws_dynamodb_table.dynamo_sessions_db,
  ]
  function_name = "${local.prefix}-be-core"
  role          = aws_iam_role.lambda.arn
  timeout       = 30
  image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.lambda_image.id}"
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

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name              = "/aws/lambda/${aws_lambda_function.websockets_app.function_name}"
  retention_in_days = 0
  lifecycle {
    prevent_destroy = false
  }
}