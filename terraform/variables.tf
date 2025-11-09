variable "aws_region" {
  description = "Primary AWS region for resources (S3 etc.)"
  type        = string
  default     = "ap-south-1"
}


variable "domain_name" {
  description = "The domain name to configure (e.g. example.com)"
  type        = string
}


variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}


variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}


variable "website_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}


variable "enable_logging" {
  description = "Enable CloudFront logging"
  type        = bool
  default     = false
}


variable "tags" {
  type = map(string)
  default = {
    Project = "static-website"
    Owner   = "Test"
    Env     = "prod"
  }
}