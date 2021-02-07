locals {
    lambda_location = "outputs/hello_lambda.zip"
}
# Module      : Iam role
resource "aws_iam_role" "lambda_iam_role" {
  count = var.enabled ? 1 : 0
  name  = var.iam_role_name

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

# Module      : Iam policy
resource "aws_iam_policy" "lambda_iam_policy" {
  count       = var.enabled ? 1 : 0
  name        = var.lambda_iam_policy_name
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

data "aws_iam_policy_document" "lambda_iam_policy_document" {
  statement {
    actions   = var.iam_actions
    effect    = "Allow"
    resources = ["*"]
  }
}

# Module      : Iam Role Policy Attachment
resource "aws_iam_role_policy_attachment" "lambda_iam_role_policy_attachment" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.lambda_iam_role.*.name)
  policy_arn = join("", aws_iam_policy.lambda_iam_policy.*.arn)
}


# Module      : Lambda layers
resource "aws_lambda_layer_version" "lambda_layer_version" {
  count               = length(var.names) > 0 && var.enabled ? length(var.names) : 0

  filename            = length(var.layer_filenames) > 0 ? element(var.layer_filenames, count.index) : null
  s3_bucket           = length(var.s3_buckets) > 0 ? element(var.s3_buckets, count.index) : null
  s3_key              = length(var.s3_keies) > 0 ? element(var.s3_keies, count.index) : null
  s3_object_version   = length(var.s3_object_versions) > 0 ? element(var.s3_object_versions, count.index) : null
  layer_name          = element(var.names, count.index)
  compatible_runtimes = element(var.compatible_runtimes, count.index)
  description         = length(var.descriptions) > 0 ? element(var.descriptions, count.index) : ""
  license_info        = length(var.license_infos) > 0 ? element(var.license_infos, count.index) : ""
}

# Module      : Archive file
provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "hello_lambda.py"
  output_path = local.lambda_location
}

locals {
  enable_environment_variables = length(var.environment_variables) > 0 ? true : false
}

# Module      : Lambda function
resource "aws_lambda_function" "lambda_function" {
  count = var.enabled ? 1 : 0

  function_name                  = var.function_name
  description                    = var.description
  role                           = join("", aws_iam_role.lambda_iam_role.*.arn)
  filename                       = local.lambda_location 
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  handler                        = var.handler
  layers                         = aws_lambda_layer_version.lambda_layer_version.*.arn
  memory_size                    = var.memory_size
  runtime                        = var.runtime
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish                        = var.publish
  kms_key_arn                    = var.kms_key_arn
  source_code_hash               = var.filename   
  tags                           = var.tags

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment  {
    variables = var.environment_variables
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
      last_modified
    ]
  }
}

# Module      : Lambda Permission
resource "aws_lambda_permission" "lambda_permission" {
  count = length(var.actions) > 0 && var.enabled ? length(var.actions) : 0

  statement_id       = length(var.statement_ids) > 0 ? element(var.statement_ids, count.index) : ""
  event_source_token = length(var.event_source_tokens) > 0 ? element(var.event_source_tokens, count.index) : null
  action             = element(var.actions, count.index)
  function_name      = join("", aws_lambda_function.lambda_function.*.function_name)
  principal          = element(var.principals, count.index)
  qualifier          = length(var.qualifiers) > 0 ? element(var.qualifiers, count.index) : null
  source_account     = length(var.source_accounts) > 0 ? element(var.source_accounts, count.index) : null
  source_arn         = length(var.source_arns) > 0 ? element(var.source_arns, count.index) : ""
}