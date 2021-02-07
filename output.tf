
# Description : Terraform Lambda function module outputs.

output "arn" {
  value       = join("", aws_lambda_function.lambda_function.*.arn)
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function."
}

