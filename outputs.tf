output "webapp_bucket_id" {
  value = aws_s3_bucket.origin.id
}

output "webapp_bucket_arn" {
  value = aws_s3_bucket.origin.arn
}

output "webapp_bucket_region" {
  value = aws_s3_bucket.origin.region
}

output "webapp_bucket_domain_name" {
  value = aws_s3_bucket.origin.bucket_regional_domain_name
}

output "webapp_bucket_origin_path" {
  value = var.origin_path
}

output "webapp_origin_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.origin.cloudfront_access_identity_path
}

output "iam_username" {
  value = aws_iam_user.deploy_user.name
}

output "iam_user_access_key_id_prev" {
  #value = aws_iam_access_key.deploy_user_key_v3.id
  value     = ""
  sensitive = true
}

output "iam_user_secret_access_key_prev" {
  #value = aws_iam_access_key.deploy_user_key_v3.secret
  value     = ""
  sensitive = true
}

output "iam_user_access_key_id_curr" {
  value     = aws_iam_access_key.deploy_user_key_v4.id
  sensitive = true
}

output "iam_user_secret_access_key_curr" {
  value     = aws_iam_access_key.deploy_user_key_v4.secret
  sensitive = true
}
