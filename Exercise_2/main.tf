# TODO: Designate a cloud provider, region, and credentials
provider "aws" {
  access_key = ""
  secret_key = ""
  region = var.aws_region
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create a folder "python" which parallel to main.tf
# and copy greet_lambda.py into "python" folder
# and create a zip file for python application
data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "${path.module}/python/"
output_path = "${path.module}/python/greet_lambda.zip"
}

resource "aws_lambda_function" "lambda_greeting" {
  filename      = "${path.module}/python/greet_lambda.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "greet_lambda.lambda_handler"
  runtime = "python3.8"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.project_udacity,
  ]

  environment {
    variables = {
        greeting = "greeting"
    }
  }
}

resource "aws_cloudwatch_log_group" "project_udacity" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}