# Static Website Hosting on AWS S3 with Terraform

A simple Terraform project that provisions an S3 bucket configured for static website hosting on AWS, with public read access enabled.

This was my first hands-on project learning Terraform + AWS.

## Architecture

```
User → S3 Bucket (Static Website Hosting, public read) → index.html / error.html / assets
```

**Resources created:**
- `aws_s3_bucket` — the bucket that stores website files
- `aws_s3_bucket_public_access_block` — disables S3's default public-access blocking so the bucket can be served publicly
- `aws_s3_bucket_website_configuration` — enables static website hosting (`index.html` / `error.html`)
- `aws_s3_bucket_policy` — bucket policy allowing public `s3:GetObject` access
- `aws_s3_object` — uploads every file from the local `./website` folder to the bucket, with content type set automatically based on file extension

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed (v1.x)
- An AWS account
- AWS CLI configured with credentials (`aws configure`)

## Project Structure

```
.
├── main.tf              # S3 bucket, hosting config, policy, and file upload
├── variable.tf           # Input variable definitions
├── terraform.tfvars       # Variable values (environment)
├── website/                # Static site source files (index.html, error.html, css, js, images)
└── README.md
```

> **Note:** The `website/` folder must exist locally with your site files before running `terraform apply` — Terraform uploads its contents to the bucket automatically.

## Variables

| Name          | Description                    | Type   | Default                        |
|---------------|---------------------------------|--------|----------------------------------|
| `bucket_name` | Name of the S3 bucket to create | string | `my-static-website-bucket-451`   |
| `environment` | Deployment environment label    | string | `dev` (set via `terraform.tfvars`) |

> S3 bucket names are globally unique across all AWS accounts — change `bucket_name` before deploying, or set it in `terraform.tfvars`.

## Usage

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd <repo-folder>
   ```

2. **Add your website files** to a `website/` folder in the project root.

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the execution plan**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **Get the website URL**
   ```bash
   terraform output website_url
   ```
   Open the returned S3 website endpoint in your browser.

## Cleanup

To avoid ongoing AWS charges, destroy the resources when done:

```bash
terraform destroy
```

## Security Note

This bucket is intentionally configured for **public read access** to serve static content directly from S3 — fine for learning/demo purposes, but review before using in production. 

## What I Learned

- Terraform basics: `init`, `plan`, `apply`, `destroy`
- Configuring an S3 bucket for static website hosting
- Writing an S3 bucket policy for public read access
- Uploading multiple local files to S3 dynamically using `fileset()` and `for_each`
- Managing infrastructure as code instead of the AWS Console

