# Static Website on AWS (Terraform)
This repository deploys a secure, scalable, and highly available static website using AWS services:

* Amazon S3 → hosts static content (HTML, CSS, JS, images)
* Amazon CloudFront → provides CDN distribution with HTTPS
* AWS Certificate Manager (ACM) → manages SSL/TLS certificate for your domain
* Amazon Route 53 → handles DNS for your custom domain

All infrastructure is provisioned via Terraform.

# Architecture Overview

```User → Route 53 → CloudFront (HTTPS) → S3 (private bucket)```

# Key features:
* Private S3 bucket accessible only via CloudFront Origin Access Identity (OAI)
* TLS 1.2 (2021) enforced via ACM
* Automatic DNS validation using Route 53
* Infrastructure as Code using Terraform
* Optional automation via helper scripts

# Prerequisites
AWS CLI configured with appropriate permissions (S3, CloudFront, Route53, ACM)
Terraform v1.2+
Registered domain in Route 53 (required for DNS validation)

# Deployment Steps

1. Initialize Terraform
```
cd terraform
terraform init
```

2. Apply Terraform Configuration
```
terraform apply \ 
-var="domain_name=example.com" \ 
-var="hosted_zone_id=Z0123456789ABC" 
```

Terraform will:
* Create a private S3 bucket \
* Request and validate an ACM certificate in us-east-1 \
* Deploy a CloudFront distribution \
* Configure Route 53 DNS \
**Note:** Wait for certificate validation (this may take a few minutes).

3. Upload Website Content
After Terraform completes, upload your static files to S3 using the helper script:
```
cd .
./scripts/upload-site.sh $(terraform output -raw s3_bucket_name)
```

4. Invalidate CloudFront Cache
Ensure new content is served immediately:
```
./scripts/invalidate-cache.sh $(terraform output -raw cloudfront_distribution_id) "/*"
```

5. Access Your Website
Visit your custom domain `(e.g. https://example.com)`. It should serve content securely via HTTPS.

# Outputs

After a successful terraform apply, note the following outputs:

**s3_bucket_name**:	Name of your S3 bucket \
**cloudfront_domain_name**:	CloudFront distribution domain \
**website_url**: HTTPS URL of your site \
**certificate_arn**: ARN of the ACM certificate

# Best Practices

1. Use OAI (Origin Access Identity) — your S3 bucket is private and accessible only via CloudFront.
2. Use DNS validation for ACM certificates — safer and automatic renewal.
3. Enforce TLSv1.2_2021 for CloudFront.
4. Add CloudFront logging (optional) for performance insights.
5. Use Terraform remote backend (S3 + DynamoDB) for state locking.
6. Integrate upload/invalidate scripts into CI/CD (e.g., GitHub Actions).