# Create the S3 bucket with a unique random suffix automatically
resource "aws_s3_bucket" "web_bucket" {
  bucket_prefix = "cloud-programming-91911488-"
}

# Upload the index.html file to the S3 bucket
resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}