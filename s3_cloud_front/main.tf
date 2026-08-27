resource aws_s3_bucket "static_website" {
  bucket = var.bucket_name

}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "first_cloudfront" {
  name                              = "first-cloudfront-deployment"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#############################################
# Bucket Policy for Public Read Access
#############################################
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.static_website.id

  depends_on = [
    aws_s3_bucket_public_access_block.block_public_access
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFront"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        } 

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.static_website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
        
      }
    ]
  })
}




#############################################
# Enable Static Website Hosting
#############################################
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("./website", "**/*")

  bucket = aws_s3_bucket.static_website.id

  key    = each.value
  source = "./website/${each.value}"

  etag = filemd5("./website/${each.value}")

  content_type = lookup(
    {
      html = "text/html"
      css  = "text/css"
      js   = "application/javascript"
      png  = "image/png"
      jpg  = "image/jpeg"
      jpeg = "image/jpeg"
      svg  = "image/svg+xml"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.first_cloudfront.id
    origin_id                = local.origin_id
  } 

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"



  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "development"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#############################################
# Output Website URL
#############################################
output "website_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}