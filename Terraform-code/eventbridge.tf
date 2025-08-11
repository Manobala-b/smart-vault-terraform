resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name                = "daily-snapshot"
  schedule_expression = "cron(0 1 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "s3_activity_rule" {
  name        = "s3-activity-notify-rule"
  description = "Triggered when S3 bucket activity is logged"
  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail = {
      eventSource = ["s3.amazonaws.com"],
      eventName   = ["PutObject", "GetObject", "DeleteObject"],
      requestParameters = {
        bucketName = [aws_s3_bucket.snapshot_bucket.bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "lambda"
  arn       = aws_lambda_function.snapshot_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn
}

resource "aws_cloudwatch_event_target" "s3_activity_target" {
  rule      = aws_cloudwatch_event_rule.s3_activity_rule.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.s3_activity_notify.arn
}