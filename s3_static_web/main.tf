resource aws_s3_bucket "static_website" {
  bucket = var.bucket_name

}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
        Sid    = "PublicReadGetObject"
        Effect = "Allow"

        Principal = "*"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "${aws_s3_bucket.static_website.arn}/*"
        ]
      }
    ]
  })
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

#############################################
# Output Website URL
#############################################
output "website_url" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}