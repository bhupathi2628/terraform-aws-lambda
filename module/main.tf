module "lambda" {
  source                     = "../../../aws-lambda/lambda-module"
  iam_role_name              = "lambda"
  lambda_iam_policy_name     = "test_policy"
 
  enabled_cloudwatch_logging = true
  enabled                    = true

  filename                   = "hello_lambda.py"
  handler                    = "index.handler"
  runtime                    = "python3.8"
  function_name              = "hello_lambda"
  timeout                    = 8

  environment_variables = {
    Serverless = "Terraform"
  }
}


