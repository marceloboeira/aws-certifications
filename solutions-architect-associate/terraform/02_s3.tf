##################### S3 #######################

resource "aws_s3_bucket" "aux_storage_01" {
  bucket = "aux-storage-01"
  acl    = "private"

  versioning {
    enabled    = true
    mfa_delete = false
  }

  lifecycle_rule {
    id      = "log"
    enabled = true
    prefix  = "log/"

    tags = {
      "rule"      = "log"
      "autoclean" = "true"
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.aux_storage_01.bucket
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PublicFolderReadAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.aux_storage_01.arn}/public/*"
    }
  ]
}
EOF
}

# Encryption Key
resource "aws_kms_key" "s3_key" {
  description             = "Sample Key Test"
  deletion_window_in_days = 7
}

# Public File
resource "aws_s3_bucket_object" "example_public" {
  bucket       = aws_s3_bucket.aux_storage_01.bucket
  key          = "public/index.html"
  source       = "etc/index.html"
  content_type = "text/html"
  etag         = filemd5("etc/index.html")
}

# Forbidden File
resource "aws_s3_bucket_object" "example_forbidden" {
  bucket       = aws_s3_bucket.aux_storage_01.bucket
  key          = "private/forbidden.html"
  source       = "etc/forbidden.html"
  content_type = "text/html"
  kms_key_id   = aws_kms_key.s3_key.arn
}
