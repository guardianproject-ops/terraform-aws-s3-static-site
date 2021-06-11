/*
 * This module creates a secure s3 bucket to function as a cloudfront origin.
 * It also creates an IAM user and access keys for a CI/CD system (such as
 * GitLab) to deploy a webapp into the bucket.
 */
data "aws_region" "current" {}

module "label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  context    = module.this.context
  attributes = ["s3-webapp"]
}

module "label_iam" {
  source         = "cloudposse/label/null"
  version        = "0.24.1"
  context        = module.label.context
  label_key_case = "title"
  delimiter      = ""
}

resource "aws_cloudfront_origin_access_identity" "origin" {
  comment = module.label.id
}

data "aws_iam_policy_document" "origin" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.origin.id}${coalesce(var.origin_path, "/")}*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.origin.id}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.origin.id
  policy = data.aws_iam_policy_document.origin.json
}

resource "aws_s3_bucket" "origin" {
  bucket = module.label.id
  acl    = "private"

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 120
  }
  tags = module.label.tags
}

resource "aws_s3_bucket_public_access_block" "origin" {
  bucket                  = aws_s3_bucket.origin.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.default]
}

resource "aws_iam_user" "deploy_user" {
  name = module.label.id
  tags = module.label.tags
}

resource "aws_iam_access_key" "deploy_user_key_v3" {
  user   = aws_iam_user.deploy_user.name
  status = "Inactive"
}

resource "aws_iam_access_key" "deploy_user_key_v4" {
  user   = aws_iam_user.deploy_user.name
  status = "Active"
}

data "aws_iam_policy_document" "deploy_rw" {
  statement {
    sid = "AllowBucketList"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.origin.arn
    ]
  }
  statement {
    sid = "AllowBucketRW"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.origin.arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "deploy_rw" {
  name   = "AllowIamUserBucketRW-${module.label_iam.id}"
  user   = aws_iam_user.deploy_user.name
  policy = data.aws_iam_policy_document.deploy_rw.json
}
