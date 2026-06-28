# 1. CloudFront Origin Access Control (OAC) to secure the connection to S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-website-oac"
  description                       = "Secures S3 bucket access from CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. The actual CloudFront Distribution (Global CDN)
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id                = "S3WebOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  # Cache configuration for optimal performance and HTTPS routing
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3WebOrigin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Global availability without any geographic blocking
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use the built-in, free CloudFront SSL/TLS certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 3. S3 Bucket Policy to grant CloudFront read permissions via OAC
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.web_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.web_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}