resource "aws_s3_bucket" "deploy_bucket" {
  bucket = var.DEPLOY_BUCKET
  acl = "private"
}

# Upload an object
resource "aws_s3_bucket_object" "upload_code_to_s3" {
  bucket = aws_s3_bucket.deploy_bucket.id
  key = "${var.AWS_SCHEDULER_VERSION}.zip"
  source = "${var.BUILD_LOCATION}/AWSScheduler-${var.AWS_SCHEDULER_VERSION}.zip"

  depends_on = [
    aws_s3_bucket.deploy_bucket
  ]
}
