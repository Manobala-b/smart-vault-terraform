resource "aws_sns_topic" "snapshot_notify" {
  name = "snapshot-notification"
}

resource "aws_sns_topic_subscription" "snapshot_email" {
  topic_arn = aws_sns_topic.snapshot_notify.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

resource "aws_sns_topic" "s3_activity_notify" {
  name = "s3-activity-notification"
}

resource "aws_sns_topic_subscription" "s3_email" {
  topic_arn = aws_sns_topic.s3_activity_notify.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.s3_activity_notify.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowEventBridgePublish",
        Effect    = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action    = "SNS:Publish",
        Resource  = aws_sns_topic.s3_activity_notify.arn
      }
    ]
  })
}
