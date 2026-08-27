# Static Website Hosting on AWS with Terraform (S3 + CloudFront)

A Terraform project that provisions a static website on AWS using a **private S3 bucket** as the origin, served securely through **CloudFront** with Origin Access Control (OAC).

Part of my Terraform + AWS learning journey.

## Architecture

```
User → CloudFront (HTTPS, CDN) → S3 Bucket (private, OAC-restricted) → index.html / error.html / assets
```

**Resources created:**
- `aws_s3_bucket` — stores the website files
- `aws_s3_bucket_public_access_block` — keeps the bucket fully private (all public access blocked)
- `aws_cloudfront_origin_access_control` (OAC) — allows only CloudFront to access the bucket
- `aws_s3_bucket_policy` — grants `s3:GetObject` to the CloudFront service principal only, scoped to this distribution
- `aws_s3_bucket_website_configuration` — sets `index.html` / `error.html`
- `aws_s3_object` — uploads all files from `./website` to the bucket, with content type inferred from file extension
- `aws_cloudfront_distribution` — CDN in front of S3, HTTPS enforced via `redirect-to-https`

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed (v1.x)
- An AWS account
- AWS CLI configured with credentials (`aws configure`)

## Project Structure

```
.
├── main.tf              # S3 bucket, CloudFront, OAC, bucket policy, file upload
├── variable.tf           # Input variable definitions
├── locals.tf              # Local values (e.g. origin_id)
├── terraform.tfvars         # Variable values
├── website/                  # Static site source files (index.html, error.html, css, js, images)
└── README.md
```

> The `website/` folder must exist locally with your site files before running `terraform apply`.

## Variables

| Name          | Description                       | Type   | Default                          |
|---------------|-------------------------------------|--------|------------------------------------|
| `bucket_name` | Name of the S3 bucket to create     | string | `cdn-static-website-bucket-451`    |
| `environment` | Deployment environment label        | string | `dev`                                |
| `aws_region`  | AWS region for deployment           | string | `us-east-1`                          |

> S3 bucket names are globally unique — change `bucket_name` before deploying.

## Usage

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd <repo-folder>
   ```

2. **Add your website files** to a `website/` folder in the project root.

3. **Initialize, plan, and apply**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Get the website URL**
   ```bash
   terraform output website_url
   ```
   This returns the CloudFront domain (e.g. `dxxxxxxx.cloudfront.net`), served over HTTPS.

> Note: CloudFront distributions can take 5–15 minutes to fully deploy.

## Cleanup

```bash
terraform destroy
```

## Security

- The S3 bucket is **fully private** — no public access, no public bucket policy.
- Only CloudFront (via OAC, scoped to this specific distribution's ARN) can read objects from the bucket.
- All viewer traffic is forced to HTTPS via `redirect-to-https`.

This is a meaningful upgrade over serving directly from a public S3 bucket — it removes public bucket exposure and adds CDN caching, HTTPS, and edge performance.

## What I Learned

- Serving S3 content securely through CloudFront using Origin Access Control (OAC)
- Writing scoped IAM/bucket policies tied to a specific CloudFront distribution ARN
- Enforcing HTTPS at the CDN layer
- Managing multi-resource infrastructure as code with Terraform

## License

MIT
