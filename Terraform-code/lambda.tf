# Zip the Lambda function code from the lambda-code/ directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code"
  output_path = "${path.module}/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "snapshot_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "smart-vault-backup"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.snapshot_notify.arn
      S3_BUCKET      = aws_s3_bucket.snapshot_bucket.bucket
      RETENTION_DAYS = "7"
    }
  }
}
