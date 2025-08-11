resource "aws_s3_bucket" "snapshot_bucket" {
  bucket        = "smartvault-snapshot-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "snapshot_lifecycle" {
  bucket = aws_s3_bucket.snapshot_bucket.id

  rule {
    id     = "move-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
  }
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "smartvault-cloudtrail-logs"
  force_destroy = true
}

