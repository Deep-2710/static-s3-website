
locals {
  site_bucket_name = "${replace(var.domain_name, ".", "-")}-site-bucket"
}

# S3 bucket (private, no website endpoint)
resource "aws_s3_bucket" "site_bucket" {
  bucket = local.site_bucket_name

  tags = merge(var.tags, {
    Name = "${var.domain_name}-site-bucket"
  })
}

resource "aws_s3_bucket_ownership_controls" "site_bucket_ownership" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name}"
}

# Bucket policy to only allow CloudFront OAI to get objects
resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.site_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Request ACM certificate in us-east-1 (for CloudFront)
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

# Create Route53 validation record for the certificate
resource "aws_route53_record" "cert_validation" {
  zone_id = var.hosted_zone_id
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  ttl     = 300
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.website_root_object

  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "s3-site-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-site-origin"

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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name]

  price_class = var.cloudfront_price_class

  tags = var.tags

  # Help SPA by returning index.html on 403/404
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.website_root_object}"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.website_root_object}"
    error_caching_min_ttl = 0
  }
}

# Route53 record to point to CloudFront
resource "aws_route53_record" "www_alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
