resource "null_resource" "ecr_image_auth" {
  triggers = {
    js_files   = md5(join("", fileset("../../server/auth/", "*.js")))
    json_files = md5(join("", fileset("../../server/auth/", "*.json")))
    dockerfile = md5(file("../../server/auth/Dockerfile"))
    data       = md5(file("../../server/auth/auth_handler.js"))
  }

  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.deploy_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.deploy_region}.amazonaws.com&&cd ../../server/auth&&docker build -t ${aws_ecr_repository.repo_ws.repository_url}:${local.ecr_image_auth_tag} .&&docker push ${aws_ecr_repository.repo_ws.repository_url}:${local.ecr_image_auth_tag}"
  }
}

data "aws_ecr_image" "lambda_image_auth" {
  depends_on = [
    null_resource.ecr_image_auth
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_auth_tag
}

resource "aws_iam_role" "lambda_auth" {
  name = "${local.prefix_auth}-lambda-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      },
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_auth" {
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
}

resource "aws_iam_policy" "lambda_auth" {
  name   = "${local.prefix_auth}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_auth.json
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment_auth" {
  role       = aws_iam_role.lambda_auth.id
  policy_arn = aws_iam_policy.lambda_auth.arn
}


resource "aws_lambda_function" "websockets_auth_app" {
  depends_on = [
    null_resource.ecr_image_auth,
    aws_ecr_repository.repo_ws,
    aws_iam_role.lambda_auth,
  ]
  function_name = "${local.prefix_auth}-be-core"
  role          = aws_iam_role.lambda_auth.arn
  timeout       = 30
  image_uri     = "${aws_ecr_repository.repo_ws.repository_url}@${data.aws_ecr_image.lambda_image_auth.id}"
  package_type  = "Image"
  memory_size   = 512

  environment {
    variables = {
      DEPLOY_REGION     = var.deploy_region,
      ENV_STAGE         = local.stage,
      COGNITO_USER_POOL = var.cognito_user_pool,
      COGNITO_CLIENT_ID = var.cognito_client_id,
    }
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_auth" {
  name              = "/aws/lambda/${aws_lambda_function.websockets_auth_app.function_name}"
  retention_in_days = 0
  lifecycle {
    prevent_destroy = false
  }
}